cd deps
mkdir build_x64
cd build_x64
cmake -G "Visual Studio 16 2019" -Ax64 ..
cmake --build . --config Release
cd ..
mkdir build_x86
cd build_x86
cmake -G "Visual Studio 16 2019" -AWin32 ..
cmake --build . --config Release
cd ../../