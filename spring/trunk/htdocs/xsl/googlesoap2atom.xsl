<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:google="urn:GoogleSearch"
                exclude-result-prefixes="google SOAP-ENV">

  <xsl:output method="xml"/>

  <xsl:param name="itemsPerPage">10</xsl:param>

  <xsl:template match="SOAP-ENV:Envelope/SOAP-ENV:Body/google:doGoogleSearchResponse/return">
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
      <title type="text">Google search for "<xsl:value-of select="translate( searchQuery, '+', ' ' )" />" via Unto.net</title>
      <Query role="request"> 
        <xsl:param name="startIndex" select="startIndex"/>
        <xsl:attribute name="startPage"><xsl:value-of select="floor( $startIndex div $itemsPerPage ) + 1"/></xsl:attribute> 
        <xsl:attribute name="searchTerms"><xsl:value-of select="searchQuery"/></xsl:attribute>
      </Query>
      <opensearch:link rel="search"
         href="/spring/search/google?format=description" type="application/opensearchdescription+xml"/>
      <opensearch:itemsPerPage><xsl:value-of select='$itemsPerPage'/></opensearch:itemsPerPage>
      <opensearch:totalResults><xsl:value-of select="estimatedTotalResultsCount" /></opensearch:totalResults>
      <opensearch:startIndex><xsl:value-of select="startIndex" /></opensearch:startIndex>
      <xsl:for-each select="resultElements/item">
      <entry>
        <title><xsl:value-of select="title"/></title>
        <link><xsl:value-of select="URL"/></link>
        <id><xsl:value-of select="URL"/></id>
        <summary type="html"><xsl:value-of select="snippet"/></summary>
      </entry>
      </xsl:for-each>
    </feed>
  </xsl:template>
</xsl:stylesheet>

