package net.unto.maven.plugins;

import java.io.File;
import java.io.IOException;
import java.util.Collection;
import java.util.Vector;

import junit.framework.Assert;
import junit.framework.TestCase;


/**
 * Uses the JUnit 3.8 conventions so that Surefire can run these tests.
 */
public class JunitRunnerTest extends TestCase
{
  private static final File CLASSES_DIRECTORY = new File( "target/classes/" );

  private static final File TEST_CLASSES_DIRECTORY = new File( "target/test-classes/" );

  private static final File[ ] TEST_CLASSPATH = { CLASSES_DIRECTORY, TEST_CLASSES_DIRECTORY };
  
  public void testGetClassNameFromFile( ) throws IOException
  {
    File classFile = new File( "target/classes/net/unto/maven/plugins/JunitMojo.class" );
    Assert.assertEquals( JunitRunner.getClassNameFromFile( CLASSES_DIRECTORY, classFile ),
                         "net.unto.maven.plugins.JunitMojo" );
  }

  public void testGetClassFiles( ) throws IOException
  {
    File classDirectory = new File( "target/classes/");
    Collection<File> classFiles = JunitRunner.getClassFiles( classDirectory );
    assertNotNull( classFiles );
    assertTrue( classFiles.size( ) == 4 );
    assertTrue( classFiles.contains( new File( "target/classes/net/unto/maven/plugins/JunitMojo.class" ) ) );
    assertTrue( classFiles.contains( new File( "target/classes/net/unto/maven/plugins/JunitRunner.class" ) ) );
    assertTrue( classFiles.contains( new File( "target/classes/net/unto/maven/plugins/ClassFileFilter.class" ) ) );
    assertTrue( classFiles.contains( new File( "target/classes/net/unto/maven/plugins/ResultAccumulator.class" ) ) );
  }
  
  public void testInstantiateJunitRunner( )
  {
    JunitRunner runner = new JunitRunner( TEST_CLASSPATH );
    assertNotNull( runner );
  }
  
  public void testRunAllTests( )
  {
    if ( System.getProperty( "net.unto.maven.plugin.testing" ) != null )
    {
      throw new Error( "Failing intentionally" );
    }
    System.setProperty( "net.unto.maven.plugin.testing" , "true" );
    JunitRunner runner = new JunitRunner( TEST_CLASSPATH );
    ResultAccumulator results = runner.runAllTests( TEST_CLASSES_DIRECTORY );
    assertNotNull( results );
    assertEquals( results.getRunCount( ), 5 );
    assertEquals( results.getFailureCount( ), 1 );
  }
  
  public void testRecursivelyFindClassFiles( )
  {
    Vector<File> files = new Vector<File>( );
    JunitRunner.recursivelyFindClassFiles( TEST_CLASSES_DIRECTORY, files );
    
  }
}
