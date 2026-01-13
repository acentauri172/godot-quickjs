#ifndef QUICKJS_WRAPPER_H
#define QUICKJS_WRAPPER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>

extern "C" {
#include "quickjs.h"
}

namespace godot {

class QuickJS : public RefCounted {
    GDCLASS(QuickJS, RefCounted)

private:
    JSRuntime *runtime;
    JSContext *context;
    String last_error;

protected:
    static void _bind_methods();

public:
    QuickJS();
    ~QuickJS();

    // Load and execute a JavaScript file
    bool load_file(const String &path);

    // Evaluate JavaScript code, return result as Variant
    Variant eval(const String &code);

    // Get last error message
    String get_error() const;

private:
    Variant js_to_variant(JSValue val);
};

}

#endif
