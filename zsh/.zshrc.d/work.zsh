# toypo
export PATH="$HOME/work/toypo-terraform/bin:$PATH"

# Android SDK / Java (openjdk@17はbrewで手動インストール。仕事用のためBrewfile非管理)
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export JVM_ARGS="-Xmx24g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"
