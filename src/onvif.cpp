#include "onvif.h"

#include <algorithm>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QAuthenticator>
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

    // Many ONVIF devices (e.g. Hikvision) protect the service endpoints with
    // HTTP Basic/Digest authentication in addition to the WS-UsernameToken in
    // the SOAP header. Answer that HTTP challenge with the same credentials.
    connect(m_nam, &QNetworkAccessManager::authenticationRequired, this,
            [this]([[maybe_unused]] QNetworkReply *reply, QAuthenticator *authenticator) {
        if (m_username.isEmpty()) {
            return;
        }
        // Only supply the credentials once per request; if they are already set
        // the previous attempt failed and retrying would loop.
        if (authenticator->user() == m_username) {
            return;
        }
        authenticator->setUser(m_username);
        authenticator->setPassword(m_password);
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
    // NOTE: A UTC QDateTime already renders a trailing "Z" with Qt::ISODate, so
    // build the timestamp explicitly to avoid a malformed "...ZZ" value.
    const QString created = QDateTime::currentDateTimeUtc().toString("yyyy-MM-ddTHH:mm:ss'Z'");

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

    // Keep only the profiles that produced a playable URI.
    QList<Profile> profiles;
    for (const Profile &p : m_profiles) {
        if (!p.uri.isEmpty()) {
            profiles.append(p);
        }
    }
    if (profiles.isEmpty()) {
        fail(tr("No playable streams were returned by the device."));
        return;
    }

    // Group profiles that belong to the same physical channel so a main and a
    // sub stream can be paired. Different devices expose this differently, so we
    // try several strategies in order of reliability.
    QVector<QVector<int>> groups = groupProfiles(profiles);

    QVariantList channels;
    int channelNumber = 0;
    for (const QVector<int> &group : groups) {
        if (group.isEmpty()) {
            continue;
        }

        // Highest resolution profile is the main stream, lowest is the sub.
        int mainIdx = group.first();
        int subIdx = group.first();
        for (int idx : group) {
            if (profileArea(profiles[idx]) > profileArea(profiles[mainIdx])) {
                mainIdx = idx;
            }
            if (profileArea(profiles[idx]) < profileArea(profiles[subIdx])) {
                subIdx = idx;
            }
        }
        // If every profile in the group has the same resolution the loop above
        // leaves sub == main; pick any other profile as the sub stream so it is
        // still used for the low-load grid view.
        if (subIdx == mainIdx && group.size() >= 2) {
            for (int idx : group) {
                if (idx != mainIdx) {
                    subIdx = idx;
                    break;
                }
            }
        }

        const Profile &main = profiles[mainIdx];
        const Profile &sub = profiles[subIdx];
        const bool hasSub = (subIdx != mainIdx);

        ++channelNumber;

        QVariantMap channel;
        QString name = main.name;
        if (name.isEmpty()) {
            name = tr("Channel %1").arg(channelNumber);
        }
        channel["name"] = name;
        channel["mainUrl"] = main.uri;
        channel["subUrl"] = hasSub ? sub.uri : QString();
        channel["mainResolution"] = (main.width > 0 && main.height > 0)
                ? QString("%1x%2").arg(main.width).arg(main.height) : QString();
        channel["subResolution"] = (hasSub && sub.width > 0 && sub.height > 0)
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

int OnvifDevice::profileArea(const Profile &p)
{
    return p.width * p.height;
}

QVector<QVector<int>> OnvifDevice::groupProfiles(const QList<Profile> &profiles)
{
    // Strategy 1: group by the video source, shared by the main and sub streams
    // of one channel. Prefer the VideoSourceConfiguration token attribute and
    // fall back to the SourceToken child.
    {
        QMap<QString, int> keyToGroup;
        QVector<QVector<int>> groups;
        bool usable = true;
        for (int i = 0; i < profiles.size(); ++i) {
            QString key = profiles[i].sourceConfigToken;
            if (key.isEmpty()) {
                key = profiles[i].sourceToken;
            }
            if (key.isEmpty()) {
                usable = false;
                break;
            }
            if (!keyToGroup.contains(key)) {
                keyToGroup[key] = groups.size();
                groups.append(QVector<int>());
            }
            groups[keyToGroup[key]].append(i);
        }

        int maxGroup = 0;
        for (const QVector<int> &g : groups) {
            maxGroup = std::max(maxGroup, int(g.size()));
        }

        // Only trust source-token grouping when it actually paired streams
        // (some group has 2+ profiles) and did not collapse every channel into a
        // single shared source. Otherwise fall through to name-based pairing.
        if (usable && maxGroup >= 2 && !(groups.size() == 1 && profiles.size() > 3)) {
            return groups;
        }
    }

    // Strategy 2: classify each profile as main or sub from its name/token and
    // pair them by order (devices list channels in a consistent order).
    {
        QVector<int> mains;
        QVector<int> subs;
        int unknown = 0;
        for (int i = 0; i < profiles.size(); ++i) {
            const QString s = (profiles[i].name + QLatin1Char(' ') + profiles[i].token).toLower();
            const bool isSub = s.contains("sub") || s.contains("second") ||
                               s.contains("minor") || s.contains("low");
            const bool isMain = s.contains("main") || s.contains("primary") ||
                                s.contains("first") || s.contains("high");
            if (isSub && !isMain) {
                subs.append(i);
            } else if (isMain && !isSub) {
                mains.append(i);
            } else {
                ++unknown;
            }
        }
        if (unknown == 0 && !mains.isEmpty() && mains.size() == subs.size()) {
            QVector<QVector<int>> groups;
            for (int k = 0; k < mains.size(); ++k) {
                QVector<int> pair;
                pair.append(mains[k]);
                pair.append(subs[k]);
                groups.append(pair);
            }
            return groups;
        }
    }

    // Strategy 3: give up on pairing and expose every profile as its own
    // channel (the user can still set a sub stream manually).
    QVector<QVector<int>> groups;
    for (int i = 0; i < profiles.size(); ++i) {
        groups.append(QVector<int>{i});
    }
    return groups;
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
                } else if (name == QLatin1String("VideoSourceConfiguration")) {
                    current.sourceConfigToken = reader.attributes().value("token").toString();
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

QByteArray OnvifDiscovery::buildProbe() const
{
    const QString messageId = QString("uuid:%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    return QString(
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

    m_socket->writeDatagram(buildProbe(), QHostAddress("239.255.255.250"), 3702);

    m_scanning = true;
    emit scanningChanged();
    m_timer->start(timeoutMs);
}

void OnvifDiscovery::scanSubnet(const QString &subnet, int timeoutMs)
{
    if (m_scanning) {
        return;
    }

    const QList<quint32> hosts = expandSubnet(subnet);
    if (hosts.isEmpty()) {
        emit finished();
        return;
    }

    reset();

    m_socket->close();
    if (!m_socket->bind(QHostAddress(QHostAddress::AnyIPv4), 0)) {
        emit finished();
        return;
    }

    m_scanning = true;
    emit scanningChanged();
    m_timer->start(timeoutMs);

    // Send a unicast probe to every host in the range. Devices reply directly
    // to our socket, so this works across routed/remote subnets.
    const QByteArray probe = buildProbe();
    for (quint32 host : hosts) {
        m_socket->writeDatagram(probe, QHostAddress(host), 3702);
    }
}

QList<quint32> OnvifDiscovery::expandSubnet(const QString &subnet)
{
    QList<quint32> hosts;
    const QString trimmed = subnet.trimmed();
    if (trimmed.isEmpty()) {
        return hosts;
    }

    // Cap the number of probed hosts to keep the scan bounded.
    const int maxHosts = 2048;

    if (trimmed.contains('/')) {
        const QStringList parts = trimmed.split('/');
        if (parts.size() != 2) {
            return hosts;
        }
        QHostAddress base(parts.at(0));
        bool ok = false;
        const int prefix = parts.at(1).toInt(&ok);
        if (base.isNull() || !ok || prefix < 0 || prefix > 32) {
            return hosts;
        }

        const quint32 baseIp = base.toIPv4Address();
        const quint32 mask = (prefix == 0) ? 0u : (0xFFFFFFFFu << (32 - prefix));
        const quint32 network = baseIp & mask;
        const quint32 broadcast = network | ~mask;

        quint32 first = network;
        quint32 last = broadcast;
        if (prefix <= 30) {
            // Skip the network and broadcast addresses for usable ranges.
            first = network + 1;
            last = broadcast - 1;
        }
        for (quint32 ip = first; ip <= last && hosts.size() < maxHosts; ++ip) {
            hosts.append(ip);
        }
    } else if (trimmed.contains('-')) {
        const QStringList parts = trimmed.split('-');
        if (parts.size() != 2) {
            return hosts;
        }
        QHostAddress from(parts.at(0).trimmed());
        QHostAddress to(parts.at(1).trimmed());
        if (from.isNull() || to.isNull()) {
            return hosts;
        }
        quint32 first = from.toIPv4Address();
        quint32 last = to.toIPv4Address();
        if (last < first) {
            qSwap(first, last);
        }
        for (quint32 ip = first; ip <= last && hosts.size() < maxHosts; ++ip) {
            hosts.append(ip);
        }
    } else {
        QHostAddress single(trimmed);
        if (!single.isNull()) {
            hosts.append(single.toIPv4Address());
        }
    }

    return hosts;
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
