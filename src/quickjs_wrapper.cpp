#include "quickjs_wrapper.h"
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void QuickJS::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_file", "path"), &QuickJS::load_file);
    ClassDB::bind_method(D_METHOD("eval", "code"), &QuickJS::eval);
    ClassDB::bind_method(D_METHOD("get_error"), &QuickJS::get_error);
}

QuickJS::QuickJS() {
    runtime = JS_NewRuntime();
    context = JS_NewContext(runtime);
    last_error = "";
}

QuickJS::~QuickJS() {
    if (context) JS_FreeContext(context);
    if (runtime) JS_FreeRuntime(runtime);
}

bool QuickJS::load_file(const String &path) {
    Ref<FileAccess> file = FileAccess::open(path, FileAccess::READ);
    if (!file.is_valid()) {
        last_error = "Failed to open file: " + path;
        return false;
    }

    String content = file->get_as_text();
    CharString utf8 = content.utf8();

    JSValue result = JS_Eval(context, utf8.get_data(), utf8.length(),
                             path.utf8().get_data(), JS_EVAL_TYPE_GLOBAL);

    if (JS_IsException(result)) {
        JSValue exc = JS_GetException(context);
        const char *str = JS_ToCString(context, exc);
        last_error = str ? String(str) : "Unknown error";
        JS_FreeCString(context, str);
        JS_FreeValue(context, exc);
        JS_FreeValue(context, result);
        return false;
    }

    JS_FreeValue(context, result);
    return true;
}

Variant QuickJS::eval(const String &code) {
    CharString utf8 = code.utf8();
    JSValue result = JS_Eval(context, utf8.get_data(), utf8.length(),
                             "<eval>", JS_EVAL_TYPE_GLOBAL);

    if (JS_IsException(result)) {
        JSValue exc = JS_GetException(context);
        const char *str = JS_ToCString(context, exc);
        last_error = str ? String(str) : "Unknown error";
        JS_FreeCString(context, str);
        JS_FreeValue(context, exc);
        JS_FreeValue(context, result);
        return Variant();
    }

    Variant ret = js_to_variant(result);
    JS_FreeValue(context, result);
    return ret;
}

String QuickJS::get_error() const {
    return last_error;
}

Variant QuickJS::js_to_variant(JSValue val) {
    if (JS_IsUndefined(val) || JS_IsNull(val)) {
        return Variant();
    }
    if (JS_IsBool(val)) {
        return JS_ToBool(context, val) != 0;
    }
    if (JS_IsNumber(val)) {
        double d;
        JS_ToFloat64(context, &d, val);
        return d;
    }
    if (JS_IsString(val)) {
        const char *str = JS_ToCString(context, val);
        String ret = str ? String(str) : "";
        JS_FreeCString(context, str);
        return ret;
    }
    if (JS_IsArray(context, val)) {
        Array arr;
        JSValue len_val = JS_GetPropertyStr(context, val, "length");
        int64_t len = 0;
        JS_ToInt64(context, &len, len_val);
        JS_FreeValue(context, len_val);

        for (int64_t i = 0; i < len; i++) {
            JSValue elem = JS_GetPropertyUint32(context, val, i);
            arr.push_back(js_to_variant(elem));
            JS_FreeValue(context, elem);
        }
        return arr;
    }
    if (JS_IsObject(val)) {
        Dictionary dict;
        JSPropertyEnum *props;
        uint32_t prop_count;

        if (JS_GetOwnPropertyNames(context, &props, &prop_count, val,
                                   JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
            for (uint32_t i = 0; i < prop_count; i++) {
                const char *key = JS_AtomToCString(context, props[i].atom);
                JSValue prop_val = JS_GetProperty(context, val, props[i].atom);
                dict[String(key)] = js_to_variant(prop_val);
                JS_FreeCString(context, key);
                JS_FreeValue(context, prop_val);
                JS_FreeAtom(context, props[i].atom);
            }
            js_free(context, props);
        }
        return dict;
    }

    // Fallback: convert to string
    const char *str = JS_ToCString(context, val);
    String ret = str ? String(str) : "";
    JS_FreeCString(context, str);
    return ret;
}
