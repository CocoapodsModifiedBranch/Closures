Pod::Spec.new do |s|
    s.name             = 'Closures'
    s.version          = '0.7.0'
    s.summary          = 'Swifty closures for UIKit and Foundation'
    s.description      = 'Closures is an iOS Framework that adds closure handlers to many of the popular\nUIKit and Foundation classes. Although this framework is a substitute for \nsome Cocoa Touch design patterns, such as Delegation and Data Sources, and \nTarget-Action, the authors make no claim regarding which is a better way to \naccomplish the same type of task. Most of the time it is a matter of style, \npreference, or convenience that will determine if any of these closure extensions \nare beneficial.\n\nWhether you’re a functional purist, dislike a particular API, or simply just \nwant to organize your code a little bit, you might enjoy using this library.'
    
    s.homepage         = 'https://github.com/vhesener/Closures'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Vinnie Hesener' }
    s.source           = { :git => 'https://github.com/vhesener/Closures.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '9.0'
    s.source_files = 'Xcode/Closures/Source'
end
