FROM ubuntu:20.04
LABEL maintainer="Martin Mirchev <mmirchev@comp.nus.edu.sg>"

RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y

RUN sed -i "$ a deb http://dk.archive.ubuntu.com/ubuntu/ xenial main " /etc/apt/sources.list
RUN sed -i "$ a deb http://dk.archive.ubuntu.com/ubuntu/ xenial main " /etc/apt/sources.list

# install experiment dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  \
 g++-5 git 0python python3 python3-pip build-essential mono-complete mono-devel mono-xbuild fsharp wget curl apt-transport-https

RUN cd /usr/bin && rm gcc && ln -s gcc-5 gcc && rm g++ && ln -s g++-5 g++

# RUN apt-get update \
#     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#         ca-certificates \
#         \
#         # .NET dependencies
#         libc6 \
#         libgcc1 \
#         libgssapi-krb5-2 \
#         libicu66 \
#         libssl1.1 \
#         libstdc++6 \
#         zlib1g 

# Install .NET
#ENV DOTNET_VERSION=8.0.1

# RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-x64.tar.gz \
#     #&& dotnet_sha512='6a1ae878efdc9f654e1914b0753b710c3780b646ac160fb5a68850b2fd1101675dc71e015dbbea6b4fcf1edac0822d3f7d470e9ed533dd81d0cfbcbbb1745c6c' \
#     #&& echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
#     && mkdir -p /usr/share/dotnet \
#     && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
#     && rm dotnet.tar.gz \
#     && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet


# ENV DOTNET_ROOT=$HOME/.dotnet
# ENV PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools

WORKDIR /opt/

RUN git clone https://bitbucket.org/spacer/code spacer-t2
WORKDIR /opt/spacer-t2
RUN git checkout spacer-t2 && ./configure && cd build && make -j 8 && make -j 8 install

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /opt
RUN wget http://nuget.org/nuget.exe


WORKDIR /opt

RUN mkdir T2

COPY . T2/
ENV T2DIR=/opt/T2

WORKDIR /opt/spacer-t2
RUN cd src/api/dotnet && xbuild && cp obj/Debug/Microsoft.Z3.* /opt/T2/src/
RUN cp build/libz3.so /opt/T2/src/

WORKDIR /opt/T2/src

RUN mono /opt/nuget.exe restore

RUN xbuild

ENTRYPOINT [ "/bin/bash" ]

# (6) Run T2 as follows (replace "Debug" by "Release" for the release build)
#       $ mono "$T2DIR/src/bin/Debug/T2.exe"
#     For example, to execute the testsuite:
#       $ pushd "$T2DIR/test" && mono "$T2DIR/src/bin/Debug/T2.exe" -tests

