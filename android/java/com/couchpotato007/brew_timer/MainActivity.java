// android/java/com/couchpotato007/brew_timer/MainActivity.java
package com.couchpotato007.brew_timer;

import android.app.NativeActivity;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;

public class MainActivity extends NativeActivity {
  public void showKeyboard(boolean show) {
    InputMethodManager imm =
      (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
    if (show) {
      imm.showSoftInput(getWindow().getDecorView(), 0);
    } else {
      imm.hideSoftInputFromWindow(
        getWindow().getDecorView().getWindowToken(), 0);
    }
  }
}
