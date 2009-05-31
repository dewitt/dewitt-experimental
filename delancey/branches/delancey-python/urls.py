from django.conf.urls.defaults import *

urlpatterns = patterns('',
  ( r'^delancey/', delancey.tracker.views.start ),
  ( r'^delancey/start/', delancey.tracker.views.start ),
  ( r'^delancey/start/(?P<username>\w+)/', delancey.tracker.views.start ),
  ( r'^delancey/start/(?P<username>\w+)/(?P<tag>\w+)/', delancey.tracker.views.start ),
  ( r'^delancey/api/', delancey.tracker.views.api ),
  ( r'^delancey/bookmarks/(?P<username>\w+)/(?P<tag>\w+)/', delancey.tracker.views.bookmarks ),
  ( r'^delancey/tags/(?P<username>\w+)/', delancey.tracker.views.tags ),
  ( r'^delancey/claim/choose/(?P<username>\w+)/', delancey.tracker.views.claim.choose ),
  ( r'^delancey/claim/complete/(?P<username>\w+)/(?P<claim_hash>\w{32})', delancey.tracker.views.claim.complete ), # POST
  ( r'^delancey/increment/(?P<username_hash>\w{32})/(?P<url_hash>\w{32})', delancey.tracker.views.increment ), # POST
  ( r'^delancey/shortname/(?P<username_hash>\w{32})/(?P<url_hash>\w{32})/', delancey.tracker.views.shortname), # POST
  ( r'^delancey/shortname/(?P<username_hash>\w{32})/(?P<url_hash>\w{32})/(?P<shortname>w+)', delancey.tracker.views.shortname ), # POST
  ( r'^admin/', include('django.contrib.admin.urls')),
)

