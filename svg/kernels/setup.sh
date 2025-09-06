# Ensure nvjitlink is visible on the PATH for Windows builds.
NVJITLINK=$(python - <<'PY'
import os, site
print(os.path.join(site.getsitepackages()[0], 'nvidia', 'nvjitlink', 'lib'))
PY
)
if [[ ":$PATH:" != *"$NVJITLINK"* ]]; then
    export PATH="$NVJITLINK:$PATH"
 fi
 
 mkdir -p build
 cd build

cmake -G "Visual Studio 17 2022" \
      -A x64 \
      -DCMAKE_CXX_COMPILER=cl \
      -DCMAKE_PREFIX_PATH=`python -c 'import torch;print(torch.utils.cmake_prefix_path)'` ..
cmake --build . --config=Release
