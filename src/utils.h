#ifndef UTILS_H
#define UTILS_H

#define PROPERTY_WRITE_IMPL(type, name, write, notify) \
    void write(const type &var) { \
        if (m_##name == var) \
            return; \
        m_##name = var; \
        Q_EMIT notify(var); \
    }

// NOTE: These macros must end with a terminator or initializer
#define PROPERTY_CONST(type, name) \
Q_PROPERTY(type name READ name CONSTANT FINAL) \
public: \
    type name() const { return m_##name; } \
private: \
    type m_##name

#define PROPERTY_MUTABLE(type, name, write, notify) \
    Q_PROPERTY(type name READ name WRITE write NOTIFY notify FINAL) \
public: \
    type name() const { return m_##name; } \
public Q_SLOTS: \
    PROPERTY_WRITE_IMPL(type, name, write, notify) \
Q_SIGNALS: \
    void notify(const type &name); \
private: \
    type m_##name

#endif // UTILS_H
