#ifndef ONVIF_H
#define ONVIF_H

#include <QObject>
#include <QVariantList>
#include <QList>
#include <QVector>
#include <QString>

class QNetworkAccessManager;
class QNetworkReply;
class QUdpSocket;
class QTimer;

// Represents a single ONVIF device (a camera, or an NVR/DVR that exposes many
// channels behind one IP address). It queries the ONVIF Media service and
// groups the returned media profiles by their video source into "channels".
// Every physical camera behind an NVR is a separate video source, so grouping
// by source token gives one entry per camera, while the highest/lowest
// resolution profiles of a source become its main/sub streams.
class OnvifDevice : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY portChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QVariantList channels READ channels NOTIFY channelsChanged)

public:
    explicit OnvifDevice(QObject *parent = nullptr);

    QString host() const { return m_host; }
    void setHost(const QString &host);
    int port() const { return m_port; }
    void setPort(int port);
    QString username() const { return m_username; }
    void setUsername(const QString &username);
    QString password() const { return m_password; }
    void setPassword(const QString &password);
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
    QVariantList channels() const { return m_channels; }

    // Connects to the device and asynchronously builds the channel list.
    // The result is delivered through the channelsChanged() signal.
    Q_INVOKABLE void fetchChannels();
    // Clears the current result and any error.
    Q_INVOKABLE void reset();

signals:
    void hostChanged();
    void portChanged();
    void usernameChanged();
    void passwordChanged();
    void busyChanged();
    void errorChanged();
    void channelsChanged();
    void finished();

private:
    struct Profile {
        QString token;
        QString name;
        QString sourceToken;        // <tt:SourceToken> child of VideoSourceConfiguration
        QString sourceConfigToken;  // token attribute of VideoSourceConfiguration
        int width = 0;
        int height = 0;
        QString uri;
    };

    QString deviceServiceUrl() const;
    QString mediaFallbackUrl() const;
    QString soapHeader() const;
    QNetworkReply *post(const QString &url, const QString &action, const QString &body);
    QString injectCredentials(const QString &rtspUri) const;

    void requestCapabilities();
    void requestProfiles();
    void requestStreamUri(int profileIndex);
    void buildChannels();

    static int profileArea(const Profile &p);
    static QVector<QVector<int>> groupProfiles(const QList<Profile> &profiles);

    void setBusy(bool busy);
    void setError(const QString &error);
    void fail(const QString &error);

    static QList<Profile> parseProfiles(const QByteArray &xml);
    static QString parseMediaXAddr(const QByteArray &xml);
    static QString parseStreamUri(const QByteArray &xml);

    QNetworkAccessManager *m_nam;
    QTimer *m_timeout;

    QString m_host;
    int m_port = 80;
    QString m_username;
    QString m_password;
    bool m_busy = false;
    QString m_error;
    QVariantList m_channels;

    QString m_mediaXAddr;
    QList<Profile> m_profiles;
    int m_pendingStreamUri = 0;
};

// Best-effort WS-Discovery probe. Sends a multicast Probe and collects the
// service addresses (XAddrs) advertised by ONVIF devices on the local network.
class OnvifDiscovery : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit OnvifDiscovery(QObject *parent = nullptr);

    bool scanning() const { return m_scanning; }
    QVariantList devices() const { return m_devices; }

    // Scans the local network (multicast WS-Discovery) for the given number of
    // milliseconds.
    Q_INVOKABLE void scan(int timeoutMs = 4000);
    // Scans an arbitrary subnet by sending unicast WS-Discovery probes to every
    // host in the range, so devices on remote/routed subnets can be found too.
    // Accepts CIDR ("192.168.5.0/24"), a range ("192.168.5.10-192.168.5.60") or
    // a single address.
    Q_INVOKABLE void scanSubnet(const QString &subnet, int timeoutMs = 6000);
    Q_INVOKABLE void reset();

signals:
    void scanningChanged();
    void devicesChanged();
    void finished();

private slots:
    void readResponses();
    void stop();

private:
    void addDevice(const QString &xaddr);
    QByteArray buildProbe() const;
    static QList<quint32> expandSubnet(const QString &subnet);

    QUdpSocket *m_socket;
    QTimer *m_timer;
    bool m_scanning = false;
    QVariantList m_devices;
};

#endif // ONVIF_H
