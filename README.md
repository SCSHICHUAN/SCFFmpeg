# Creat a framework project
   #### Xcode setings :
    1.Selected->TARGETS->Build Setings (search:Other link)->Other Linker Flags
      add: item 
       "-all_load"
       "-read_only_relocs"
       "suppress"
    
    2.Selected->TARGETS->Build Setings (search:Mach-)->Mach-O Type
       selected:item
        Dynamic Library
    
    3.Selected->TARGETS->Bulib Phases->Headers->Public
      add:your headers
      Expose your own created header files, cannot ffmpeg header files
    
    3.Add FFmpeg source to project and seting search Heade ,seting library
    
    4.Delete the header file automatically created by the project
      The compilation may not pass because of this automatically created header file
    
    5.Introduce to other projects
       Selected->TARGETS->Bulib Phases->Headers->Copy Files
           selected: Frameworks
                add: your framework
      
