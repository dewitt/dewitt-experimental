<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
                xmlns:yahoo="urn:yahoo:srch">

  <xsl:output method="xml"/>

  <xsl:param name="searchTerms" select="searchTerms"/>
  <xsl:param name="itemsPerPage" select="itemsPerPage"/>

  <xsl:template match="/">

    <rss version="2.0" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      <channel>
      <title>unto.net: <xsl:value-of select="translate( $searchTerms, '+', ' ' )" /> on Yahoo</title>
      <description>Yahoo! Search Results for <xsl:value-of select="translate( $searchTerms, '+', ' ' )" /> via unto.net</description>
      <openSearch:startIndex><xsl:value-of select="yahoo:ResultSet/@firstResultPosition" /></openSearch:startIndex>
      <openSearch:itemsPerPage><xsl:value-of select="$itemsPerPage" /></openSearch:itemsPerPage>
      <openSearch:totalResults><xsl:value-of select="yahoo:ResultSet/@totalResultsAvailable" /></openSearch:totalResults>
      <xsl:for-each select="yahoo:ResultSet/yahoo:Result">
      <item>
        <title><xsl:value-of select="yahoo:Title"/></title>
        <link><xsl:value-of select="yahoo:Url"/></link>
        <guid><xsl:value-of select="yahoo:Url"/></guid>
        <description><xsl:value-of select="yahoo:Summary"/></description>
      </item>
      </xsl:for-each>
      </channel>
    </rss>
  </xsl:template>
</xsl:stylesheet>

