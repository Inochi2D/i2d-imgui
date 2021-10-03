cd deps
mkdir build
cd build
cmake -G "Visual Studio 16 2019" -Ax64 ..
cmake --build . --config Release
cd ../../