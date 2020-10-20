FROM nginx:alpine
LABEL author="Tom Saleeba"
LABEL description="reverse proxy that can protect our precious app server from the internet"

ADD entrypoint.sh /
ENTRYPOINT ["sh", "/entrypoint.sh"]
