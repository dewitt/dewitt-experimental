package net.unto.maven.plugins;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.Collection;
import java.util.Vector;

import org.junit.runner.JUnitCore;
import org.junit.runner.Result;

public class JunitRunner
{
  private URL[ ] _classpath = null;
  
  /**
   * Instantiate a new JunitRunner.
   * 
   * @param classpathFilenames array of directories to be added to the default classpath for the unit tests
   */
  public JunitRunner( File[ ] classpathFilenames )
  {
    assert( classpathFilenames != null );
    _classpath = toUrlArray( classpathFilenames );
  }

  /**
   * Find all .class files in the specified directory and execute their Junit 4 tests.
   * 
   * @param testClassDirectory the root directory of the test classes to be run
   * @return the report after all tests have been run
   */
  public ResultAccumulator runAllTests( File testClassDirectory )
  {
    ResultAccumulator resultAccumulator = new ResultAccumulator( );

    if ( ( testClassDirectory == null ) || !testClassDirectory.isDirectory( ) )
    {
      return resultAccumulator;
    }

    Collection<File> testClassFiles = getClassFiles( testClassDirectory );
    
    assert( testClassFiles != null );
    
    Collection<Class> testClasses = getTestClasses( testClassDirectory, testClassFiles );
    
    assert( testClasses != null );
    
    for ( Class testClass : testClasses )
    {
      Result result = getJunitCoreViaTestClassLoader( ).run( testClass );
      resultAccumulator.addResult( result );
    }

    return resultAccumulator;
  }

  protected static Collection<File> getClassFiles( File directory )
  {
    assert ( directory != null );
    Vector<File> files = new Vector<File>( );
    recursivelyFindClassFiles( directory, files );
    return files;
  } 
  
  protected static void recursivelyFindClassFiles( File directory, Collection<File> files )
  {
    assert ( directory != null );
    assert ( files != null );
    assert ( directory.isDirectory( ) );


    for ( File entry : directory.listFiles( new ClassFileFilter( ) ) )
    {
      if ( !entry.isDirectory( ) )
      {
        files.add( entry );
      }
      else
      {
        recursivelyFindClassFiles( entry, files );
      }
    }
  }


  private Collection<Class> getTestClasses( File testClassDirectory, Collection<File> files )
  {
    Vector<Class> classes = new Vector<Class>( );
    ClassLoader testClassLoader = getTestClassLoader( );

    for ( File file : files )
    {
      String className = getClassNameFromFile( testClassDirectory, file );
      try
      {
        classes.add( testClassLoader.loadClass( className ) );
      }
      catch ( ClassNotFoundException e )
      {
        throw new RuntimeException( e );
      }
    }
    return classes;
  }
  
  private ClassLoader getTestClassLoader( )
  {
    return new URLClassLoader( _classpath, getClass( ).getClassLoader( ) );
  }
  
  protected static String getClassNameFromFile( File classDirectory, File classFile )
  {
    assert ( classDirectory != null );
    assert ( classFile != null );
    assert ( classDirectory.isDirectory( ) );
    assert ( classFile.isFile( ) );

    String classFilePath = getCanonicalPath( classFile );
    String classDirectoryPath = getCanonicalPath( classDirectory );

    assert ( classFilePath != null );
    assert ( classDirectoryPath != null );
    assert ( classFilePath.startsWith( classDirectoryPath ) );
    assert ( classFilePath.endsWith( ".class" ) );

    String classPath = classFilePath.substring( classDirectoryPath.length( ) + 1, classFilePath.indexOf( ".class" ) );

    assert ( classPath.indexOf( File.separatorChar ) != 0 );

    return classPath.replace( File.separatorChar, '.' );
  }
  
  protected static String getCanonicalPath( File file )
  {
    assert ( file != null );
    try
    {
      return file.getCanonicalPath( );
    }
    catch ( IOException e )
    {
      throw new RuntimeException( e );
    }
  }
  
  private JUnitCore getJunitCoreViaTestClassLoader( )
  {
    try
    {
      return ( JUnitCore ) getTestClassLoader( ).loadClass( "org.junit.runner.JUnitCore" ).newInstance( );
    }
    catch ( ClassNotFoundException e )
    {
      throw new RuntimeException( e );
    }
    catch ( InstantiationException e )
    {
      throw new RuntimeException( e );
    }
    catch ( IllegalAccessException e )
    {
      throw new RuntimeException( e );
    }
  }
  
  protected static URL[ ] toUrlArray( File[ ] files )
  {
    assert ( files != null );
    URL[ ] urls = new URL[ files.length ];
    for ( int i = 0; i < files.length; i++ )
    {
      urls[ i ] = toUrl( files[ i ] );
    }
    return urls;
  }

  protected static URL toUrl( File file )
  {
    assert ( file != null );
    try
    {
      return file.toURL( );
    }
    catch ( MalformedURLException e )
    {
      throw new RuntimeException( e );
    }
  }
}
