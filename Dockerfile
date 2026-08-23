FROM ghcr.io/cirruslabs/flutter:3.24.0

# تثبيت الأدوات الأساسية
USER root
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    unzip \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# ضبط متغيرات البيئة
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# تثبيت Android SDK
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd /tmp && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip -q commandlinetools-linux-11076708_latest.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm commandlinetools-linux-11076708_latest.zip

# قبول التراخيص وتثبيت المكونات
RUN yes | sdkmanager --licenses > /dev/null 2>&1 || true
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# ضبط Flutter
RUN flutter config --android-sdk ${ANDROID_HOME}
RUN flutter doctor --android-licenses || true

# العودة للمستخدم العادي
USER cirrus
WORKDIR /app

# نسخ ملفات المشروع
COPY --chown=cirrus:cirrus . .

# تثبيت الحزم
RUN flutter pub get

# أمر البناء الافتراضي
CMD ["flutter", "build", "apk", "--release"]
