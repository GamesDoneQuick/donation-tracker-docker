# Docker Development Quickstart (Experimental)

These instructions were written with Engine 19.03.12 and Compose 1.26.2 in mind, and assume you are familiar enough
with Docker to spin up Compose. 

The Dockerfiles in this repo use Python 3.6, but any later version should work for the initial setup.

Clone this repo, then while in the root of this repo, start up a new Django Project like the [Django Tutorial](https://docs.djangoproject.com/en/2.2/intro/tutorial01/).

```
pip install django~=2.2
django-admin startproject tracker_project
```

Clone the base repo while in the root of this repo.

```
git clone https://github.com/GamesDoneQuick/donation-tracker-docker.git django-donation-tracker
```

Add the following apps to the `INSTALLED_APPS` section of `tracker_project/settings.py`:

```
    'channels',
    'post_office',
    'paypal.standard.ipn',
    'tracker',
    'timezone_field',
    'ajax_select',
    'mptt',
```

Add the following chunk somewhere in `settings.py`:

```python
from tracker import ajax_lookup_channels
AJAX_LOOKUP_CHANNELS = ajax_lookup_channels.AJAX_LOOKUP_CHANNELS
ASGI_APPLICATION = 'tracker_project.routing.application'
CHANNEL_LAYERS = {'default': {'BACKEND': 'channels.layers.InMemoryChannelLayer'}}
DOMAIN = 'localhost:8000'
```

Create a file next called `routing.py` next to `settings.py` and put the following in it:

```python
from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.urls import path

import tracker.routing

application = ProtocolTypeRouter({
    'websocket': AllowedHostsOriginValidator(
        AuthMiddlewareStack(
            URLRouter(
                [path('tracker/', URLRouter(tracker.routing.websocket_urlpatterns))]
            )
        )
    ),
})
```

Edit the `urls.py` file to look something like this:

```python
from django.contrib import admin
from django.urls import path, include

import tracker.urls
import ajax_select.urls

urlpatterns = [
    path('admin/', admin.site.urls),
    path('admin/lookups/', include(ajax_select.urls)),
    path('tracker/', include(tracker.urls, namespace='tracker')),
]
```

After that, `docker-compose -f docker-compose.dev.yml up -d --build` should (eventually) get you going. Once everything
is running, [the index page](http://localhost:8000/tracker/) should load up in your browser.

You'll want to make a super user so you can access the [admin pages](http://localhost:8000/admin/), 
`docker-compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser` will do this for you.

# Deploying with Docker (experimental)

There are a lot of services out there that let you deploy with Docker Compose. It is out of scope for this document to
cover any of them here. The file provided here should give you a good starting point. Take special care when setting up
the DB, you'll likely want to use an externally managed DB with its own backups, but those questions are better left for
your service provider. 
