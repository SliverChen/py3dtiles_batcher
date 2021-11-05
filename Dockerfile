FROM python:3.10.0
WORKDIR /usr/src/app
COPY requirements.txt ./

RUN sed -i "s/archive.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list \
   && sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list \
   && sed -i "s/security.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list \
   && sed -i "s/httpredir.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list \
   && pip install -U pip \
   && pip config set global.index-url http://mirrors.aliyun.com/pypi/simple \
   && pip config set install.trusted-host mirrors.aliyun.com

RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENTRYPOINT ["python"]
CMD ["./setup.py","install"]
