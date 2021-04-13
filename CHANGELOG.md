# 1.3.0
* Up required Ruby version to 2.6.

# 1.2.1
* Development: Now that we're running Semaphore, no need for Travis (#31)
* Reduce dependencies listed in gemspec (#30) (Dependency on Rails removed,
  only need to depend on ActiveRecord)

# 1.2.0
* Set minimum Ruby version from 2.3 to 2.4 (2.3 is EOL and no longer maintained)
* Fixed an issue where a UUID would be unpacked again while it's a perfectly
  fine UUID already. Thanks @sirwolfgang.

# 1.1.1
* Fixes possible SQL injection for ActiveRecord columns typed with
  MySQLBinUUID::Type. Thank you @ejoubaud, @geoffevason and @viraptor.

# 1.1.0
* Set minimum Ruby version from 2.2 to 2.3
* Set default Ruby version to 2.5.1
* Updated README shipped with the gem

# 1.0.0
* Initial release.
