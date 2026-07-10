// DISCLAIMER Claude Code Usage
// This is very ass that you have to go through the fucking jvm to get
// keyboad inputs
//
// Why is android so ass

#include <android/input.h>
#include <android_native_app_glue.h>
#include <jni.h>
#include <stdbool.h>
#include <stdint.h>

#define TEXT_QUEUE_CAP 64

typedef struct {
  int32_t codepoints[TEXT_QUEUE_CAP];
  int head, tail, count;
} TextQueue;

static TextQueue g_text_queue = {0};
static int32_t (*g_prev_input_handler)(struct android_app *app,
                                       AInputEvent *event) = NULL;
static bool g_backspace_pressed = false;
static bool g_enter_pressed = false;

extern struct android_app *GetAndroidApp(void);

static void text_queue_push(int32_t cp) {
  if (g_text_queue.count >= TEXT_QUEUE_CAP)
    return;
  g_text_queue.codepoints[g_text_queue.tail] = cp;
  g_text_queue.tail = (g_text_queue.tail + 1) % TEXT_QUEUE_CAP;
  g_text_queue.count++;
}

static int32_t jni_get_unicode_char(JNIEnv *env, int32_t device_id,
                                    int32_t key_code, int32_t meta_state) {
  jclass kcmClass = (*env)->FindClass(env, "android/view/KeyCharacterMap");
  if (!kcmClass)
    return 0;
  jmethodID loadMethod = (*env)->GetStaticMethodID(
      env, kcmClass, "load", "(I)Landroid/view/KeyCharacterMap;");
  jobject kcm =
      (*env)->CallStaticObjectMethod(env, kcmClass, loadMethod, device_id);
  if (!kcm)
    return 0;
  jmethodID getMethod = (*env)->GetMethodID(env, kcmClass, "get", "(II)I");
  return (*env)->CallIntMethod(env, kcm, getMethod, key_code, meta_state);
}

static int32_t android_input_hook(struct android_app *app, AInputEvent *event) {
  if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY &&
      AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_DOWN) {

    int32_t key_code = AKeyEvent_getKeyCode(event);
    int32_t meta_state = AKeyEvent_getMetaState(event);
    int32_t device_id = AInputEvent_getDeviceId(event);

    if (key_code == AKEYCODE_DEL) {
      g_backspace_pressed = true;
    } else if (key_code == AKEYCODE_ENTER ||
               key_code == AKEYCODE_NUMPAD_ENTER) {
      g_enter_pressed = true;
    } else {
      JNIEnv *env;
      JavaVM *vm = app->activity->vm;
      bool attached = false;
      if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK) {
        (*vm)->AttachCurrentThread(vm, &env, NULL);
        attached = true;
      }

      int32_t unicode =
          jni_get_unicode_char(env, device_id, key_code, meta_state);
      if (unicode > 0)
        text_queue_push(unicode);

      if (attached)
        (*vm)->DetachCurrentThread(vm);
    }
  }

  if (g_prev_input_handler)
    return g_prev_input_handler(app, event);
  return 0;
}

void android_install_text_input_hook(void) {
  struct android_app *app = GetAndroidApp();
  if (!app)
    return;
  if (app->onInputEvent != android_input_hook) {
    g_prev_input_handler = app->onInputEvent;
    app->onInputEvent = android_input_hook;
  }
}

void android_show_keyboard(bool show) {
  struct android_app *app = GetAndroidApp();
  if (!app)
    return;

  JNIEnv *env;
  JavaVM *vm = app->activity->vm;
  (*vm)->AttachCurrentThread(vm, &env, NULL);

  jobject activity = app->activity->clazz;
  jclass activityClass = (*env)->GetObjectClass(env, activity);

  jclass contextClass = (*env)->FindClass(env, "android/content/Context");
  jfieldID imsField = (*env)->GetStaticFieldID(
      env, contextClass, "INPUT_METHOD_SERVICE", "Ljava/lang/String;");
  jobject imsStr = (*env)->GetStaticObjectField(env, contextClass, imsField);

  jmethodID getSystemService =
      (*env)->GetMethodID(env, activityClass, "getSystemService",
                          "(Ljava/lang/String;)Ljava/lang/Object;");
  jobject imm =
      (*env)->CallObjectMethod(env, activity, getSystemService, imsStr);
  jclass immClass = (*env)->GetObjectClass(env, imm);

  jmethodID getWindow = (*env)->GetMethodID(env, activityClass, "getWindow",
                                            "()Landroid/view/Window;");
  jobject window = (*env)->CallObjectMethod(env, activity, getWindow);
  jmethodID getDecorView =
      (*env)->GetMethodID(env, (*env)->GetObjectClass(env, window),
                          "getDecorView", "()Landroid/view/View;");
  jobject decorView = (*env)->CallObjectMethod(env, window, getDecorView);

  if (show) {
    jmethodID showSoftInput = (*env)->GetMethodID(
        env, immClass, "showSoftInput", "(Landroid/view/View;I)Z");
    (*env)->CallBooleanMethod(env, imm, showSoftInput, decorView, 0);
  } else {
    jmethodID getToken =
        (*env)->GetMethodID(env, (*env)->GetObjectClass(env, decorView),
                            "getWindowToken", "()Landroid/os/IBinder;");
    jobject token = (*env)->CallObjectMethod(env, decorView, getToken);
    jmethodID hideSoftInput = (*env)->GetMethodID(
        env, immClass, "hideSoftInputFromWindow", "(Landroid/os/IBinder;I)Z");
    (*env)->CallBooleanMethod(env, imm, hideSoftInput, token, 0);
  }

  (*vm)->DetachCurrentThread(vm);
}

int32_t android_poll_text_char(void) {
  if (g_text_queue.count == 0)
    return 0;
  int32_t cp = g_text_queue.codepoints[g_text_queue.head];
  g_text_queue.head = (g_text_queue.head + 1) % TEXT_QUEUE_CAP;
  g_text_queue.count--;
  return cp;
}

bool android_poll_backspace(void) {
  if (g_backspace_pressed) {
    g_backspace_pressed = false;
    return true;
  }
  return false;
}

bool android_poll_enter(void) {
  if (g_enter_pressed) {
    g_enter_pressed = false;
    return true;
  }
  return false;
}
