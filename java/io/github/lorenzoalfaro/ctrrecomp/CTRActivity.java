package io.github.lorenzoalfaro.ctrrecomp;

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
}
