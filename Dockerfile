FROM python:3.7 as base

WORKDIR /usr/src/app

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

# Install en_US.UTF-8 locale required for localization
RUN apt-get update && apt-get install -y locales && \
        sed -i 's/\# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
        locale-gen en_US.UTF-8

# Install js dependencies
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
        apt-get install -y nodejs && \
        npm install -g yarn

FROM base as dependencies

# Install tracker dependencies
COPY django-donation-tracker/package.json \
        django-donation-tracker/setup.py \
        django-donation-tracker/yarn.lock \
        django-donation-tracker/README.md \
        ./django-donation-tracker/

RUN pip install --upgrade pip && \
        (cd django-donation-tracker && mkdir tracker && pip install . && yarn --production)

FROM base

COPY django-donation-tracker ./django-donation-tracker
COPY --from=dependencies /root/.cache /root/.cache
COPY --from=dependencies /usr/src/app/django-donation-tracker/node_modules /usr/src/app/django-donation-tracker/node_modules

# Install tracker itself
RUN pip install --upgrade pip && \
        (cd django-donation-tracker && python setup.py package) && \
        pip install ./django-donation-tracker

# Install additional python dependencies
RUN pip install psycopg2-binary~=2.8.6

COPY tracker_project/manage.py requirements.txt ./
COPY tracker_project/tracker_project ./tracker_project
