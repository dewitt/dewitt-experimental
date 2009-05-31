from django.db import models

class User(models.Model):
  '''The user keeps track of hashed passwords.'''
  username_hash = models.CharField(maxlength=32,primary_key=True)
  password_hash = models.CharField(maxlength=32)

  def __str__(self):
    return self.username_hash

  class Admin:
    pass
          

class Counter(models.Model):
  username_hash = models.ForeignKey(User,db_column='username_hash')
  url_hash = models.CharField(maxlength=32,db_index=True)
  count = models.IntegerField()
  shortname = models.CharField(maxlength=255)
  last_clicked = models.DateTimeField()

  def __str__(self):
    return 'User: %s, Url: %s' % ( self.username_hash, self.url_hash )
        
  unique_together = (("username_hash", "url_hash"))

  class Admin:
    pass


class Claim(models.Model):
  username_hash = models.ForeignKey(User,db_column='username_hash')
  password_hash = models.CharField(maxlength=32)
  claim_hash = models.CharField(maxlength=32,db_index=True)
  created = models.DateTimeField(auto_now=True)

  def __str__(self):
    return 'User: %s, Claim: %s' % ( self.username_hash, self.claim_hash )

  class Admin:
    pass
