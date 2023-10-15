#ifndef GLOBAL_H
#define GLOBAL_H

#define PROPERTY_WRITE_IMPL(type, name, write, notify) \
    void write(const type &var) { \
        if (m_##name == var) \
            return; \
        m_##name = var; \
        emit notify(var); \
    }

#endif // GLOBAL_H
