#include "onvif.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUdpSocket>
#include <QHostAddress>
#include <QTimer>
#include <QUrl>
#include <QUuid>
#include <QDateTime>
#include <QCryptographicHash>
#include <QXmlStreamReader>
#include <QStringList>
#include <QMap>

// ---------------------------------------------------------------------------
// OnvifDevice
// ---------------------------------------------------------------------------

OnvifDevice::OnvifDevice(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_timeout(new QTimer(this))
{
    m_timeout->setSingleShot(true);
    m_timeout->setInterval(15000);
    connect(m_timeout, &QTimer::timeout, this, [this] {
        if (m_busy) {
            fail(tr("Connection timed out."));
        }
    });
}

void OnvifDevice::setHost(const QString &host)
{
    if (m_host == host) {
        return;
    }
    m_host = host;
    emit hostChanged();
}

void OnvifDevice::setPort(int port)
{
    if (m_port == port) {
        return;
    }
    m_port = port;
    emit portChanged();
}

void OnvifDevice::setUsername(const QString &username)
{
    if (m_username == username) {
        return;
    }
    m_username = username;
    emit usernameChanged();
}

void OnvifDevice::setPassword(const QString &password)
{
    if (m_password == password) {
        return;
    }
    m_password = password;
    emit passwordChanged();
}

void OnvifDevice::reset()
{
    m_timeout->stop();
    m_mediaXAddr.clear();
    m_profiles.clear();
    m_pendingStreamUri = 0;
    setError(QString());
    if (!m_channels.isEmpty()) {
        m_channels.clear();
        emit channelsChanged();
    }
    setBusy(false);
}

void OnvifDevice::fetchChannels()
{
    if (m_busy) {
        return;
    }
    if (m_host.trimmed().isEmpty()) {
        setError(tr("Host address is empty."));
        return;
    }

    reset();
    setBusy(true);
    m_timeout->start();
    requestCapabilities();
}

QString OnvifDevice::deviceServiceUrl() const
{
    return QString("http://%1:%2/onvif/device_service").arg(m_host).arg(m_port);
}

QString OnvifDevice::mediaFallbackUrl() const
{
    return QString("http://%1:%2/onvif/media_service").arg(m_host).arg(m_port);
}

QString OnvifDevice::soapHeader() const
{
    if (m_username.isEmpty()) {
        return QString();
    }

    const QByteArray nonce = QUuid::createUuid().toRfc4122();
    const QString created = QDateTime::currentDateTimeUtc().toString(Qt::ISODate) + "Z";

    QByteArray digestSource;
    digestSource.append(nonce);
    digestSource.append(created.toUtf8());
    digestSource.append(m_password.toUtf8());
    const QByteArray digest = QCryptographicHash::hash(digestSource, QCryptographicHash::Sha1);

    return QString(
        "<s:Header>"
        "<Security s:mustUnderstand=\"1\" xmlns=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\">"
        "<UsernameToken>"
        "<Username>%1</Username>"
        "<Password Type=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest\">%2</Password>"
        "<Nonce EncodingType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary\">%3</Nonce>"
        "<Created xmlns=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">%4</Created>"
        "</UsernameToken>"
        "</Security>"
        "</s:Header>")
        .arg(m_username.toHtmlEscaped(),
             QString::fromLatin1(digest.toBase64()),
             QString::fromLatin1(nonce.toBase64()),
             created);
}

QNetworkReply *OnvifDevice::post(const QString &url, const QString &action, const QString &body)
{
    const QString envelope = QString(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\">"
        "%1<s:Body>%2</s:Body>"
        "</s:Envelope>")
        .arg(soapHeader(), body);

    QNetworkRequest request((QUrl(url)));
    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QString("application/soap+xml; charset=utf-8; action=\"%1\"").arg(action));

    return m_nam->post(request, envelope.toUtf8());
}

void OnvifDevice::requestCapabilities()
{
    const QString body =
        "<GetCapabilities xmlns=\"http://www.onvif.org/ver10/device/wsdl\">"
        "<Category>Media</Category>"
        "</GetCapabilities>";

    QNetworkReply *reply = post(deviceServiceUrl(),
                                "http://www.onvif.org/ver10/device/wsdl/GetCapabilities", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            m_mediaXAddr = parseMediaXAddr(reply->readAll());
        }
        if (m_mediaXAddr.isEmpty()) {
            // Fall back to the conventional media endpoint.
            m_mediaXAddr = mediaFallbackUrl();
        }

        requestProfiles();
    });
}

void OnvifDevice::requestProfiles()
{
    m_timeout->start();

    const QString body = "<GetProfiles xmlns=\"http://www.onvif.org/ver10/media/wsdl\"/>";
    QNetworkReply *reply = post(m_mediaXAddr,
                                "http://www.onvif.org/ver10/media/wsdl/GetProfiles", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            fail(tr("Failed to get media profiles: %1").arg(reply->errorString()));
            return;
        }

        m_profiles = parseProfiles(reply->readAll());
        if (m_profiles.isEmpty()) {
            fail(tr("No media profiles found. Check the credentials."));
            return;
        }

        m_pendingStreamUri = m_profiles.size();
        for (int i = 0; i < m_profiles.size(); ++i) {
            requestStreamUri(i);
        }
    });
}

void OnvifDevice::requestStreamUri(int profileIndex)
{
    m_timeout->start();

    const QString body = QString(
        "<GetStreamUri xmlns=\"http://www.onvif.org/ver10/media/wsdl\">"
        "<StreamSetup xmlns=\"http://www.onvif.org/ver10/schema\">"
        "<Stream>RTP-Unicast</Stream>"
        "<Transport><Protocol>RTSP</Protocol></Transport>"
        "</StreamSetup>"
        "<ProfileToken>%1</ProfileToken>"
        "</GetStreamUri>")
        .arg(m_profiles.at(profileIndex).token.toHtmlEscaped());

    QNetworkReply *reply = post(m_mediaXAddr,
                                "http://www.onvif.org/ver10/media/wsdl/GetStreamUri", body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, profileIndex] {
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError && profileIndex < m_profiles.size()) {
            const QString uri = parseStreamUri(reply->readAll());
            m_profiles[profileIndex].uri = injectCredentials(uri);
        }

        if (--m_pendingStreamUri <= 0) {
            buildChannels();
        }
    });
}

QString OnvifDevice::injectCredentials(const QString &rtspUri) const
{
    if (rtspUri.isEmpty() || m_username.isEmpty()) {
        return rtspUri;
    }

    QUrl url(rtspUri);
    if (!url.isValid()) {
        return rtspUri;
    }
    url.setUserName(m_username);
    url.setPassword(m_password);

    return url.toString(QUrl::FullyEncoded);
}

void OnvifDevice::buildChannels()
{
    m_timeout->stop();

    // Group profiles by their video source token. Each source is one physical
    // camera (behind an NVR there is one source per channel).
    QMap<QString, QList<Profile>> grouped;
    QStringList order;
    for (const Profile &p : m_profiles) {
        if (p.uri.isEmpty()) {
            continue;
        }
        const QString key = p.sourceToken.isEmpty() ? p.token : p.sourceToken;
        if (!grouped.contains(key)) {
            order.append(key);
        }
        grouped[key].append(p);
    }

    QVariantList channels;
    int channelNumber = 0;
    for (const QString &key : order) {
        QList<Profile> profiles = grouped.value(key);

        // Highest resolution profile is the main stream, lowest is the sub.
        Profile main = profiles.first();
        Profile sub = profiles.first();
        for (const Profile &p : profiles) {
            if (p.width * p.height > main.width * main.height) {
                main = p;
            }
            if (p.width * p.height < sub.width * sub.height) {
                sub = p;
            }
        }

        ++channelNumber;

        QVariantMap channel;
        QString name = main.name;
        if (name.isEmpty()) {
            name = tr("Channel %1").arg(channelNumber);
        }
        channel["name"] = name;
        channel["mainUrl"] = main.uri;
        channel["subUrl"] = (sub.token != main.token) ? sub.uri : QString();
        channel["mainResolution"] = (main.width > 0 && main.height > 0)
                ? QString("%1x%2").arg(main.width).arg(main.height) : QString();
        channel["subResolution"] = (sub.token != main.token && sub.width > 0 && sub.height > 0)
                ? QString("%1x%2").arg(sub.width).arg(sub.height) : QString();
        channels.append(channel);
    }

    if (channels.isEmpty()) {
        fail(tr("No playable streams were returned by the device."));
        return;
    }

    m_channels = channels;
    emit channelsChanged();

    setBusy(false);
    emit finished();
}

void OnvifDevice::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

void OnvifDevice::setError(const QString &error)
{
    if (m_error == error) {
        return;
    }
    m_error = error;
    emit errorChanged();
}

void OnvifDevice::fail(const QString &error)
{
    m_timeout->stop();
    m_pendingStreamUri = 0;
    setError(error);
    setBusy(false);
    emit finished();
}

QString OnvifDevice::parseMediaXAddr(const QByteArray &xml)
{
    QXmlStreamReader reader(xml);
    bool inMedia = false;

    while (!reader.atEnd()) {
        reader.readNext();
        const QString name = reader.name().toString();

        if (reader.isStartElement()) {
            if (name == QLatin1String("Media")) {
                inMedia = true;
            } else if (inMedia && name == QLatin1String("XAddr")) {
                return reader.readElementText();
            }
        } else if (reader.isEndElement() && name == QLatin1String("Media")) {
            inMedia = false;
        }
    }

    return QString();
}

QList<OnvifDevice::Profile> OnvifDevice::parseProfiles(const QByteArray &xml)
{
    QList<Profile> profiles;
    QXmlStreamReader reader(xml);

    bool inProfile = false;
    Profile current;

    while (!reader.atEnd()) {
        reader.readNext();
        const QString name = reader.name().toString();

        if (reader.isStartElement()) {
            if (name == QLatin1String("Profiles")) {
                inProfile = true;
                current = Profile();
                current.token = reader.attributes().value("token").toString();
            } else if (inProfile) {
                if (name == QLatin1String("Name") && current.name.isEmpty()) {
                    current.name = reader.readElementText();
                } else if (name == QLatin1String("SourceToken")) {
                    current.sourceToken = reader.readElementText();
                } else if (name == QLatin1String("Width") && current.width == 0) {
                    current.width = reader.readElementText().toInt();
                } else if (name == QLatin1String("Height") && current.height == 0) {
                    current.height = reader.readElementText().toInt();
                }
            }
        } else if (reader.isEndElement() && name == QLatin1String("Profiles") && inProfile) {
            profiles.append(current);
            inProfile = false;
        }
    }

    return profiles;
}

QString OnvifDevice::parseStreamUri(const QByteArray &xml)
{
    QXmlStreamReader reader(xml);

    while (!reader.atEnd()) {
        reader.readNext();
        if (reader.isStartElement() && reader.name() == QLatin1String("Uri")) {
            return reader.readElementText();
        }
    }

    return QString();
}

// ---------------------------------------------------------------------------
// OnvifDiscovery
// ---------------------------------------------------------------------------

OnvifDiscovery::OnvifDiscovery(QObject *parent)
    : QObject(parent)
    , m_socket(new QUdpSocket(this))
    , m_timer(new QTimer(this))
{
    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout, this, &OnvifDiscovery::stop);
    connect(m_socket, &QUdpSocket::readyRead, this, &OnvifDiscovery::readResponses);
}

void OnvifDiscovery::reset()
{
    if (!m_devices.isEmpty()) {
        m_devices.clear();
        emit devicesChanged();
    }
}

void OnvifDiscovery::scan(int timeoutMs)
{
    if (m_scanning) {
        return;
    }

    reset();

    m_socket->close();
    if (!m_socket->bind(QHostAddress(QHostAddress::AnyIPv4), 0)) {
        emit finished();
        return;
    }

    const QString messageId = QString("uuid:%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    const QByteArray probe = QString(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<e:Envelope xmlns:e=\"http://www.w3.org/2003/05/soap-envelope\" "
        "xmlns:w=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" "
        "xmlns:d=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\" "
        "xmlns:dn=\"http://www.onvif.org/ver10/network/wsdl\">"
        "<e:Header>"
        "<w:MessageID>%1</w:MessageID>"
        "<w:To e:mustUnderstand=\"true\">urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>"
        "<w:Action e:mustUnderstand=\"true\">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>"
        "</e:Header>"
        "<e:Body>"
        "<d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types></d:Probe>"
        "</e:Body>"
        "</e:Envelope>")
        .arg(messageId).toUtf8();

    m_socket->writeDatagram(probe, QHostAddress("239.255.255.250"), 3702);

    m_scanning = true;
    emit scanningChanged();
    m_timer->start(timeoutMs);
}

void OnvifDiscovery::readResponses()
{
    while (m_socket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(int(m_socket->pendingDatagramSize()));
        m_socket->readDatagram(datagram.data(), datagram.size());

        QXmlStreamReader reader(datagram);
        while (!reader.atEnd()) {
            reader.readNext();
            if (reader.isStartElement() && reader.name() == QLatin1String("XAddrs")) {
                const QString xaddrs = reader.readElementText();
                // XAddrs may contain several whitespace-separated URLs.
                const QStringList urls = xaddrs.simplified().split(QChar(' '));
                for (const QString &url : urls) {
                    if (!url.isEmpty()) {
                        addDevice(url);
                    }
                }
            }
        }
    }
}

void OnvifDiscovery::addDevice(const QString &xaddr)
{
    QUrl url(xaddr);
    if (!url.isValid() || url.host().isEmpty()) {
        return;
    }

    for (const QVariant &existing : m_devices) {
        if (existing.toMap().value("host").toString() == url.host()) {
            return;
        }
    }

    QVariantMap device;
    device["host"] = url.host();
    device["port"] = url.port(80);
    device["xaddr"] = xaddr;
    m_devices.append(device);
    emit devicesChanged();
}

void OnvifDiscovery::stop()
{
    if (!m_scanning) {
        return;
    }
    m_socket->close();
    m_scanning = false;
    emit scanningChanged();
    emit finished();
}
