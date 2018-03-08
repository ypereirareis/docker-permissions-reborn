FROM php:7.2.3-fpm-alpine3.7

ARG PROJECT_DIR_ARG='/usr/share/nginx/html'
ENV PROJECT_DIR=$PROJECT_DIR_ARG

RUN mkdir -p $PROJECT_DIR
COPY ./project $PROJECT_DIR
RUN chown -R www-data:www-data $PROJECT_DIR
WORKDIR $PROJECT_DIR
USER www-data

CMD ["php-fpm"]
