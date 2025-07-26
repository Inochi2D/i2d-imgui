import core.sys.windows.windows;
import core.runtime;
import std.string;
import std.file;
import std.exception : enforce;

import bindbc.sdl,
bindbc.sdl.dynload,
bindbc.imgui.dynload,
bindbc.imgui.config,
bindbc.imgui.ogl,
bindbc.imgui.bind.imgui,
bindbc.opengl;

//@("nolint(dscanner.style.phobos_naming_convention)")
//extern (Windows)
//int WinMain(
//    HINSTANCE hInstance,
//    HINSTANCE hPrevInstance,
//    LPSTR lpCmdLine,
//    int nCmdShow
//) {
//    int result;
//
//    try {
//        Runtime.initialize();
//        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
//        Runtime.terminate();
//    } catch (Throwable e) {
//        MessageBoxA(null, e.toString().toStringz(), null, MB_ICONEXCLAMATION);
//        result = 0; // failed
//    }
//
//    return result;
//}
//
//int myWinMain(
//    HINSTANCE hInstance,
//    HINSTANCE hPrevInstance,
//    LPSTR lpCmdLine,
//    int nCmdShow
//) {
//    auto game = new Game();
//    game.MainLoop();
//
//    return 0;
//}

int main()
{
    auto game = new Game();
    game.MainLoop();

    return 0;
}

class Game {
    ImVec4 clear_color;

    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;

    ImFontConfig config;

    ImGuiViewport* main_viewport;
    ImFont* menu_fnt;

    this() {
        // Init

        loadSDL();

        version (BindImGui_Dynamic) {
            loadImGui();
            if (isImGuiLoaded() != ImGuiSupport.ImGui_1_79) {
                new StringException("ImGui not loaded!");
            }
        }

        // Create window with graphics context
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengl"); // https://github.com/ocornut/imgui/issues/4264#issuecomment-868560023 still nothing...
        SDL_WindowFlags window_flags = cast(SDL_WindowFlags)(SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE /*| SDL_WINDOW_ALLOW_HIGHDPI*/ );
        window = SDL_CreateWindow("Dear ImGui SDL2+OpenGL3 example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, window_flags);

        const char* glsl_version = "#version 330";
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

        gl_context = SDL_GL_CreateContext(window);

        SDL_GL_MakeCurrent(window, gl_context);

        SDL_GL_SetSwapInterval(1); // Enable vsync

        loadOpenGL();

        igCreateContext(null);
        io = igGetIO();

        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable; // Enable Docking

        igStyleColorsDark(null);

        config.MergeMode = false;

        auto arialData = std.file.read("C:/Windows/Fonts/arial.ttf");

        menu_fnt = ImFontAtlas_AddFontFromMemoryTTF(
            io.Fonts,
            arialData.ptr,
            cast(int) arialData.length,
            16.0f,
            &config,
            null
        );

        if (menu_fnt is null) {
            throw new Exception("Null menu_fnt right after loading?!");
        }

        ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
        ImGuiOpenGLBackend.init(glsl_version);

        clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

        main_viewport = igGetMainViewport();
    }

    ~this() {
        // Cleanup
        ImGuiOpenGLBackend.shutdown();
        ImGui_ImplSDL2_Shutdown();
        igDestroyContext(null);

        if (gl_context !is null) {
            SDL_GL_DeleteContext(gl_context);
            gl_context = null;
        }
        if (window !is null) {
            SDL_DestroyWindow(window);
            window = null;
        }
        SDL_Quit();
    }

    void MainLoop() {
        io = igGetIO(); // It seems the io pointer gets stale, so grab it again.

        // ChatGPT recommended a dummy frame to force font atlas upload before the main loop
        // It doesn't seem to hurt or help things for me.
        //ImGuiOpenGLBackend.new_frame();
        //ImGui_ImplSDL2_NewFrame();
        //igNewFrame();

        // Main loop turn on
        bool done = false;
        while (!done) {
            // Poll and handle events (inputs, window resize, etc.)
            // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
            // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
            // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
            // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
                ImGui_ImplSDL2_ProcessEvent(&event);
                if (event.type == SDL_QUIT)
                    done = true;
                if (event.type == SDL_WINDOWEVENT
                    && event.window.event == SDL_WINDOWEVENT_CLOSE
                    && event.window.windowID == SDL_GetWindowID(window)
                    )
                    done = true;
            }

            // Start the Dear ImGui frame
            ImGuiOpenGLBackend.new_frame();
            ImGui_ImplSDL2_NewFrame();
            igNewFrame();

            igDockSpaceOverViewport(main_viewport, cast(ImGuiDockNodeFlags) ImGuiDockNodeFlags.PassthruCentralNode, null);

            // I stripped out the demo+other window from ImGui here

            glViewport(0, 0, cast(int) io.DisplaySize.x, cast(int) io.DisplaySize.y);
            glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
            glClear(GL_COLOR_BUFFER_BIT);

            // this is where I render my fullscreen triangle with texture.
            // Just leaving it commented so you know the the order I'm doing stuff
            // glUseProgram(shaderProgram); 
            // glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
            // menu_bg.bind();
            // glDrawArrays(GL_TRIANGLES, 0, 3);
            // menu_bg.unbind();

            auto draw_list = igGetBackgroundDrawList(main_viewport); // draw before everything else
            auto x = main_viewport.Pos.x + 60; // Not even sure where +60 puts this
            auto y = main_viewport.Pos.y + 60; // But that's a prolem for when it doesn't just explode
            if (menu_fnt is null) {
                throw new Exception("Null menu_fnt!");
            }
            // else {
            //     throw new Exception(format!"menu_fnt: 0x%x"(menu_fnt));
            // }

            igPushFont(menu_fnt); // boom
            ImDrawList_AddText(draw_list, ImVec2(x, y), igGetColorU32(
                    cast(int) ImGuiCol.FrameBg), toStringz("Clipped Text"));
            igPopFont();

            //igEndFrame();

            // Rendering
            igRender();
            ImGuiOpenGLBackend.render_draw_data(igGetDrawData());

            // Update and Render additional Platform Windows
            // (Platform functions may change the current OpenGL context, so we save/restore it to make it easier to paste this code elsewhere.
            //  For this specific demo app we could also call SDL_GL_MakeCurrent(window, gl_context) directly)
            if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) {
                SDL_Window* backup_current_window = SDL_GL_GetCurrentWindow();
                SDL_GLContext backup_current_context = SDL_GL_GetCurrentContext();
                igUpdatePlatformWindows();
                igRenderPlatformWindowsDefault();
                SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
            }
            SDL_GL_SwapWindow(window);
        }
    }
}