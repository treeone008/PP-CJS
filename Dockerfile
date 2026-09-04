FROM nginx:latest
RUN echo "<h1>PayGuard API (Automated by Jenkins)</h1>" > /usr/share/nginx/html/index.html
EXPOSE 80
