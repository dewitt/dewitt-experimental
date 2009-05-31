<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:openSearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:yahoo="urn:yahoo:prods">

  <xsl:output method="xml"/>

  <xsl:param name="searchTerms" select="searchTerms"/>
  <xsl:param name="itemsPerPage" select="itemsPerPage"/>

  <xsl:template match="/">

    <rss version="2.0" xmlns:openSearch="http://a9.com/-/spec/opensearch/1.1/">
      <channel>
      <title>unto.net: <xsl:value-of select="translate( $searchTerms, '+', ' ' )" /> on Yahoo</title>
      <description>Yahoo! Search Results for <xsl:value-of select="translate( $searchTerms, '+', ' ' )" /> via unto.net</description>
      <openSearch:startIndex><xsl:value-of select="yahoo:ResultSet/@firstResultPosition" /></openSearch:startIndex>
      <openSearch:itemsPerPage><xsl:value-of select="$itemsPerPage" /></openSearch:itemsPerPage>
      <openSearch:totalResults><xsl:value-of select="yahoo:ResultSet/@totalResultsAvailable" /></openSearch:totalResults>
      <xsl:for-each select="yahoo:ResultSet/yahoo:Result/yahoo:Catalog">
      <item>
        <title><xsl:value-of select="yahoo:ProductName"/></title>
        <link><xsl:value-of select="yahoo:Url"/></link>
        <guid><xsl:value-of select="yahoo:Url"/></guid>
        <description>
         <xsl:if test="yahoo:Thumbnail">
          &lt;a href="<xsl:value-of select="yahoo:Url"/>"&gt;
           &lt;img src="<xsl:value-of select="yahoo:Thumbnail/yahoo:Url" />"
            border="0"
            align="top"
            style="float: left; padding: 5px;"
            height="<xsl:value-of select="yahoo:Thumbnail/yahoo:Height" />"
            width="<xsl:value-of select="yahoo:Thumbnail/yahoo:Width" />" /&gt;&lt;/a&gt;
         </xsl:if>
         <xsl:choose>
           <xsl:when test="yahoo:Description"><xsl:value-of select="yahoo:Description" /></xsl:when>
           <xsl:when test="yahoo:Summary"><xsl:value-of select="yahoo:Summary" /></xsl:when>
           <xsl:otherwise><xsl:value-of select="yahoo:ProductName" /></xsl:otherwise> 
         </xsl:choose>
        </description>
      </item>
      </xsl:for-each>
      </channel>
    </rss>
  </xsl:template>
</xsl:stylesheet>

