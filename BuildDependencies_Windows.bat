cd deps
mkdir build_windows_x64_cimguiStatic_StaticCRT
cd build_windows_x64_cimguiStatic_StaticCRT
cmake -G "Visual Studio 17 2022" -Ax64 -DSTATIC_CIMGUI= -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x64_cimguiStatic_DynamicCRT
cd build_windows_x64_cimguiStatic_DynamicCRT
cmake -G "Visual Studio 17 2022" -Ax64 -DSTATIC_CIMGUI= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x64_cimguiDynamic_StaticCRT
cd build_windows_x64_cimguiDynamic_StaticCRT
cmake -G "Visual Studio 17 2022" -Ax64 -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x64_cimguiDynamic_DynamicCRT
cd build_windows_x64_cimguiDynamic_DynamicCRT
cmake -G "Visual Studio 17 2022" -Ax64 ..
cmake --build . --config Release
cd ..
mkdir build_windows_x86_cimguiStatic_StaticCRT
cd build_windows_x86_cimguiStatic_StaticCRT
cmake -G "Visual Studio 17 2022" -AWin32 -DSTATIC_CIMGUI= -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x86_cimguiStatic_DynamicCRT
cd build_windows_x86_cimguiStatic_DynamicCRT
cmake -G "Visual Studio 17 2022" -AWin32 -DSTATIC_CIMGUI= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x86_cimguiDynamic_StaticCRT
cd build_windows_x86_cimguiDynamic_StaticCRT
cmake -G "Visual Studio 17 2022" -AWin32 -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_x86_cimguiDynamic_DynamicCRT
cd build_windows_x86_cimguiDynamic_DynamicCRT
cmake -G "Visual Studio 17 2022" -AWin32 ..
cmake --build . --config Release
cd ..
mkdir build_windows_arm64_cimguiStatic_StaticCRT
cd build_windows_arm64_cimguiStatic_StaticCRT
cmake -G "Visual Studio 17 2022" -AARM64 -DSTATIC_CIMGUI= -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_arm64_cimguiStatic_DynamicCRT
cd build_windows_arm64_cimguiStatic_DynamicCRT
cmake -G "Visual Studio 17 2022" -AARM64 -DSTATIC_CIMGUI= ..
cmake --build . --config Release
cd ..
mkdir build_windows_arm64_cimguiDynamic_StaticCRT
cd build_windows_arm64_cimguiDynamic_StaticCRT
cmake -G "Visual Studio 17 2022" -AARM64 -DWINDOWS_STATIC_CRT= ..
cmake --build . --config Release
cd ..
mkdir build_windows_arm64_cimguiDynamic_DynamicCRT
cd build_windows_arm64_cimguiDynamic_DynamicCRT
cmake -G "Visual Studio 17 2022" -AARM64 ..
cmake --build . --config Release
cd ..
cd ../../