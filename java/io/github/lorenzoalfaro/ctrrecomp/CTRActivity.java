package io.github.lorenzoalfaro.ctrrecomp;

import org.libsdl.app.SDLActivity;

// SDL's activity runs SDL_main() from libmain.so (the recompiled game and its runtime).
public class CTRActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] {"SDL2", "main"};
    }
}
