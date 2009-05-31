<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
                xmlns:google="urn:GoogleSearch">

  <xsl:output method="xml"/>

  <xsl:template match="SOAP-ENV:Envelope/SOAP-ENV:Body/google:doGoogleSearchResponse/return">
    <rss version="2.0" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      <channel>
        <title>unto.net: <xsl:value-of select="translate( searchQuery, '+', ' ' )" /> on Google</title>
        <description>Google Search Results for <xsl:value-of select="translate( searchQuery, '+', ' ' )" /> via unto.net</description>
        <openSearch:itemsPerPage>10</openSearch:itemsPerPage>
        <openSearch:totalResults><xsl:value-of select="estimatedTotalResultsCount" /></openSearch:totalResults>
        <openSearch:startIndex><xsl:value-of select="startIndex - 1" /></openSearch:startIndex>
        <xsl:for-each select="resultElements/item">
          <item>
            <title><xsl:value-of select="title"/></title>
            <link><xsl:value-of select="URL"/></link>
            <description><xsl:value-of select="snippet"/></description>
          </item>
        </xsl:for-each>
      </channel>
    </rss>
  </xsl:template>
</xsl:stylesheet>

