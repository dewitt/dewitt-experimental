<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:atom="http://www.w3.org/2005/Atom"
                exclude-result-prefixes="atom">

  <xsl:output method="xml"/>

  <xsl:param name="itemsPerPage" select="itemsPerPage" value="10"/>

  <xsl:template match="/">
    <rss version="2.0" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
      <channel>
        <title><xsl:value-of select='atom:feed/atom:title'/></title>
        <opensearch:itemsPerPage><xsl:value-of select='atom:feed/opensearch:itemsPerPage'/></opensearch:itemsPerPage>
        <opensearch:totalResults><xsl:value-of select="atom:feed/opensearch:totalResults" /></opensearch:totalResults>
        <opensearch:startIndex><xsl:value-of select="atom:feed/opensearch:startIndex" /></opensearch:startIndex>
        <xsl:for-each select="atom:feed/atom:entry">
          <item>
            <title><xsl:value-of select="atom:title"/></title>
            <link><xsl:value-of select="atom:link"/></link>
            <guid><xsl:value-of select="atom:id"/></guid>
            <description><xsl:value-of select="atom:summary"/></description>
          </item>
        </xsl:for-each>
      </channel>
    </rss>
  </xsl:template>
</xsl:stylesheet>

