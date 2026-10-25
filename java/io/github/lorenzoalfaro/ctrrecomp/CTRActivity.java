package io.github.lorenzoalfaro.ctrrecomp;

import android.util.Log;
import android.view.KeyEvent;

import org.libsdl.app.SDLActivity;

// SDL's activity runs SDL_main() from libmain.so (the recompiled game and its runtime).
public class CTRActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] {"SDL2", "main"};
    }

    // Command-line options for testing, e.g.
    //   adb shell am start -n <package>/.CTRActivity -e args "--frames 600 --keys 300:start"
    @Override
    protected String[] getArguments() {
        String args = getIntent() != null ? getIntent().getStringExtra("args") : null;
        if (args == null || args.trim().isEmpty()) return new String[0];
        return args.trim().split("\\s+");
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int code = event.getKeyCode();
        // A controller's guide button (the Logitech button on an F710) arriving as BUTTON_MODE
        // would be an Android TV shortcut that leaves the game: swallow it. (The BRAVIA maps it
        // to HOME, which the system handles before any app.)
        if (code == KeyEvent.KEYCODE_BUTTON_MODE) {
            if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0)
                Log.i("CTR", "guide button ignored (" + event.getDevice() + ")");
            return true;
        }
        return super.dispatchKeyEvent(event);
    }
}
