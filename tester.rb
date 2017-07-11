#!/usr/bin/ruby

def whereIsPackage(packageName)
  '''(String) -> String. Returns the location of a given package. Returns "packageName:" if package is not installed.'''

  exec( "whereis " + packageName + "> 'packageLocation.txt'") # system() returns boolean to see if successful and executes whereas exec() just executes
  return 2
  f = File.new("packageLocation.txt", "r")
  location = File.read(f)
  return "22"
end

def doesPackageExist(packageName)
  '''(String) -> Boolean. '''
  if whereIsPackage(packageName) == packageName + ":\n"
    return false
  else
    return true
  end
end

p whereIsPackage("trefsdafdasfsde")
