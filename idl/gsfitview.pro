forward_function gsfit_log2map, gsfit_log2list

pro gsfitview_event,event
  widget_control,widget_info(event.top,Find_By_Uname='STATEBASE'),get_uvalue=state
  subdirectory=['resource', 'bitmaps']
  case TAG_NAMES(event, /STRUCTURE_NAME) of
    'WIDGET_KILL_REQUEST':BEGIN
                              answer=dialog_message(/question,'Do you want to quit GSFITVIEW?')
                              if strupcase(answer) eq 'YES' then begin
                                ptr_free,state.pmaps
                                widget_control,event.top,/destroy
                                return
                              end
                           END  
     '':begin
                  if tag_exist(event,'MAPS') then begin
                    case size(event.maps,/tname) of
                      'STRUCT': begin
                                  maps=event.maps
                                  goto,opencube
                                end
                      'STRING': begin
                                 file=event.maps
                                 if file_exist(file) then goto,openfile
                                 end 
                      else:
                     endcase                    
                         
                  end  
                 end 
     else:
    endcase                     
  IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_DRAW' THEN BEGIN
     if ptr_valid(state.pmaps)  then begin
       widget_control,event.id,get_value=win_ppd,get_uvalue=g
       wset,win_ppd
       !x=g.x
       !y=g.y
       !z=g.z
       !p=g.p
       widget_control,state.wx,get_uvalue=xpix
       widget_control,state.wy,get_uvalue=ypix
       case event.type of      
          0: begin
              ;MouseDown
              cursor,x,y,/nowait,/data
              mindx=min(abs(xpix-x),imin)
              x=xpix[imin]
              mindy=min(abs(ypix-y),jmin)
              y=ypix[jmin]
                case event.press of
                 1:begin                 
                    device,set_graphics_function=6
                    state.ppd_dev_xrange=[event.x,event.x]
                    state.ppd_dev_yrange=[event.y,event.y]
                    case 1 of
                      state.cursor_on: begin
                                        state.ppd_data_xrange=[x,x]
                                        state.ppd_data_yrange=[y,y]
                                       end                 
                      else: begin
                              if (state.proi_on eq 0) or  (state.left_button_down eq 0) then begin
                                state.whist.xroi->Remove,/all
                                state.whist.yroi->Remove,/all
                              end
                              state.whist.xroi->Add,x
                              state.whist.yroi->Add,y
                            end
                      endcase
                     if (state.proi_on eq 1)  then begin
                      plots, [state.whist.xroi(state.whist.xroi->Count()-2),x],[state.whist.yroi(state.whist.yroi->Count()-2),y],color=255
                     endif
                     state.left_button_down=1
                   end
                 4:begin  
                     if (state.proi_on eq 0) then begin
                       widget_control,state.wx,get_uvalue=xpix
                       widget_control,state.wy,get_uvalue=ypix
                       mindeltax=min(abs(xpix-x),cx)
                       widget_control,state.wx,set_value=cx
                       mindeltay=min(abs(ypix-y),cy)
                       widget_control,state.wy,set_value=cy
                       draw=1
                     endif else begin
                      state.left_button_down=0
                      if state.whist.xroi->Count() ge 2 then begin
                        state.whist.xroi->Add,x
                        state.whist.yroi->Add,y
                        state.whist.xroi->Add,state.whist.xroi(0)
                        state.whist.yroi->Add,state.whist.yroi(0)
                      endif else begin
                        state.whist.xroi->Remove,/all
                        state.whist.yroi->Remove,/all
                      endelse
                      draw=2
                     endelse
                   end
                 else:  
                endcase 
            end
            
          1:begin
             ;Mouse Up
              if event.release eq 1 then begin
                cursor,x,y,/nowait,/data
                mindx=min(abs(xpix-x),imin)
                x=xpix[imin]
                mindy=min(abs(ypix-y),jmin)
                y=ypix[jmin]
                state.left_button_down=state.proi_on   
                state.ppd_dev_xrange[1]=event.x
                state.ppd_dev_yrange[1]=event.y
                state.ppd_dev_xrange=state.ppd_dev_xrange[sort(state.ppd_dev_xrange)]
                x0= state.ppd_dev_xrange[0]
                x1= state.ppd_dev_xrange[1]
                y0= state.ppd_dev_yrange[0]
                y1= state.ppd_dev_yrange[1]
                if ~state.proi_on then plots,/dev,[x0,x0,x1,x1,x0],[y0,y1,y1,y0,y0]   ; Erase current box
                case 1 of
                 state.cursor_on: begin
                                      state.ppd_data_xrange[1]=x
                                      state.ppd_data_yrange[1]=y
                                      state.ppd_data_yrange=state.ppd_data_yrange[sort(state.ppd_data_yrange)]
                                      draw=1
                                     end        
                  state.rroi_on: begin
                                  x0=(state.whist.xroi->Remove(/all))[0]
                                  y0=(state.whist.yroi->Remove(/all))[0]
                                  x1=x
                                  y1=y
                                  if (x1 ne x0) AND (y1 NE y0) then begin
                                    x_list=[x0,x0,x1,x1,x0]
                                    y_list=[y0,y1,y1,y0,y0] 
                                    state.whist.xroi->Add,x_list,/extract
                                    state.whist.yroi->Add,y_list,/extract
                                  endif else begin
                                      state.whist.xroi->Remove,/all
                                      state.whist.yroi->Remove,/all
                                  endelse
                                  draw=2
                                 end
                  state.froi_on : begin
                                  if state.whist.xroi->Count() ge 2 then begin
                                    state.whist.xroi->Add,x
                                    state.whist.yroi->Add,y
                                    state.whist.xroi->Add,state.whist.xroi(0)
                                    state.whist.yroi->Add,state.whist.yroi(0)
                                  endif else begin
                                    state.whist.xroi->Remove,/all
                                    state.whist.yroi->Remove,/all
                                  endelse
                                  device,set_graphics_function=3
                                  draw=2
                                end
                  else:     begin
                              state.ppd_dev_xrange[0]=event.x
                              state.ppd_dev_yrange[0]=event.y
                            end         
                endcase                 
                if state.froi_on eq 0 then device,set_graphics_function=3
              end
             end
             
            2: begin
                ;MouseMove
                cursor,data_x,data_y,/nowait,/data
                mindx=min(abs(xpix-data_x),imin)
                data_x=xpix[imin]
                mindy=min(abs(ypix-data_y),jmin)
                data_y=ypix[jmin]
                if state.left_button_down eq 1 then begin
                  x0= state.ppd_dev_xrange[0]
                  x1= state.ppd_dev_xrange[1]
                  y0= state.ppd_dev_yrange[0]
                  y1= state.ppd_dev_yrange[1]
                  state.ppd_dev_xrange[1]=(x=event.x)
                  state.ppd_dev_yrange[1]=(y=event.y)
                  case 1 of 
                    state.froi_on: begin
                                      plots,/dev,[x1,x],[y1,y],thick=2
                                      state.whist.xroi->Add,data_x
                                      state.whist.yroi->Add,data_y
                                   end
                    state.proi_on: begin
;                                      plots,/dev,[x0,x1],[y0,y1]   ; Erase current box
;                                      plots,/dev,[x0,x],[y0,y]       ; Draw new box
                                   end  
                    else: begin
                            plots,/dev,[x0,x0,x1,x1,x0],[y0,y1,y1,y0,y0]   ; Erase current box
                            plots,/dev,[x0,x0,x,x,x0],[y0,y,y,y0,y0]       ; Draw new box
                          end
                  endcase
                end
              end
          else:
       endcase
    end 
  ENDIF
  case event.id of
   state.wtime:draw=1
   state.wfreq:draw=1
   state.wpol:draw=1
   state.wx:draw=1
   state.wy:draw=1
   state.wmaplist:draw=1
   state.wHist.check:begin
                      gsfitview_display_statistics,state
                     end
   state.wHistView:begin
                     if event.select then  gsfitview_display_statistics,state
                   end     
   state.wPlotView:begin
                     if event.select then   gsfitview_display_statistics,state
                   end   
   state.wROISum:begin
                     gsfitview_display_statistics,state
                   end                          
   state.wHist.range:begin
                       widget_control,state.wparmlist,get_uvalue=parm_ranges
                       if n_elements(parm_ranges) eq 0 then parm_ranges=dblarr(2,n_elements(parm_names))
                       parm_index=widget_info(state.wparmlist,/DROPLIST_SELECT)
                       widget_control,event.id,get_value=range
                       parm_ranges[*,parm_index]=range
                       widget_control,state.wparmlist,set_uvalue=parm_ranges
                       gsfitview_display_statistics,state
                     end   
   state.wHist.save:gsfitview_display_statistics,state,/save
   state.wHist.wROIsave:begin
                         file=dialog_pickfile(title='Select a filename to save ROI coordinates',filter='*.sav',/overwrite,/write)
                         if file ne '' then begin
                           xroi=state.whist.xroi->ToArray()
                           yroi=state.whist.yroi->ToArray()
                           save,xroi,yroi,file=file
                         endif
                         end
   state.wHist.wROIopen:begin                           
                           widget_control,state.wMouse.Cursor,send_event={ID:0L,Top:0l,Handler:0L,SELECT:1L} 
                           if widget_info(state.wMouse.RROI,/button) then widget_control,state.wMouse.RROI,send_event={ID:0L,Top:0l,Handler:0L,SELECT:0L}                           
                           if widget_info(state.wMouse.PROI,/button) then widget_control,state.wMouse.PROI,send_event={ID:0L,Top:0l,Handler:0L,SELECT:0L}
                           if widget_info(state.wMouse.FROI,/button) then widget_control,state.wMouse.FROI,send_event={ID:0L,Top:0l,Handler:0L,SELECT:0L}
                           file=dialog_pickfile(title='Select a filename to restore a set of ROI coordinates',filter='*.sav',/read)
                           if file ne '' then begin
                             restore,file
                             if n_elements(xroi) eq 0 or n_elements(yroi) eq 0 then begin
                              answ=dialog_message('Unexpected file content!')
                             endif else begin
                              state.whist.xroi->Remove,/all
                              state.whist.yroi->Remove,/all
                              state.whist.xroi->Add,xroi,/extract
                              state.whist.yroi->Add,yroi,/extract
                              draw=1
                             endelse
                           endif                      
                        end
   state.wHist.bins:begin
   draw=1
   end 
         
   state.wparmlist:begin
                    draw=1
                   end 
   state.wTimeProfileOptions:draw=1
   state.wSpectralPlotOptions:draw=1
   state.wpalette: begin
                     xloadct,/silent,/block
                     draw=1
                   end    
   state.wopen: begin
                 file=dialog_pickfile(filter='*.sav',title='Select an IDL sav file containg a parmfit structure')
                 openfile:
                 default,file,''
                 if file ne '' then begin                 
                   osav=obj_new('idl_savefile',file)
                   names=osav->names()
                   valid=0
                   for i=0,n_elements(names)-1 do begin
                     osav->restore,names[i]
                     e=execute('result=size('+names[i]+',/tname)')
                     if (result eq 'STRUCT') then begin
                       e=execute('maps=temporary('+names[i]+')')
                     endif
                   endfor
                   obj_destroy,osav

                  opencube:
                  if size(maps,/tname) eq 'STRUCT' then begin
                    if tag_exist(maps,'DATAMAPS') then begin
                        sz=size(maps.datamaps.data)
                        if tag_exist(maps.datamaps,'dimensions') then begin
                          case sz[0] of
                            3:begin
                               nx=sz[1]
                               ny=sz[2]
                               nfreqs=sz[3]
                               npols=1
                               ntimes=1
                              end
                            4: begin
                                nx=sz[1]
                                ny=sz[2]
                                nfreqs=sz[3]
                                npols=sz[4]
                                ntimes=1
                               end 
                            5: begin
                                 nx=sz[1]
                                 ny=sz[2]
                                 nfreqs=sz[3]
                                 npols=sz[4]
                                 ntimes=sz[5]
                               end  
                            else: begin
                                   answ=dialog_message('Unexpected data format, operation aborted!')
                                   return
                                  end    
                           endcase
                         endif else begin
                           case sz[0] of
                             3:begin
                               nx=sz[1]
                               ny=sz[2]
                               nfreqs=sz[3]
                               npols=1
                               ntimes=1
                             end
                             4: begin
                               nx=sz[1]
                               ny=sz[2]
                               nfreqs=sz[3]
                               npols=1
                               ntimes=sz[4]
                             end
                             5: begin
                               nx=sz[1]
                               ny=sz[2]
                               nfreqs=sz[3]
                               npols=sz[4]
                               ntimes=sz[5]
                             end
                             else: begin
                               answ=dialog_message('Unexpected data format, operation aborted!')
                               return
                             end
                           endcase
                           maps=rep_tag_value(maps, reform(maps.fitmaps,nfreqs,npols,ntimes),'fitmaps')
                           maps=rep_tag_value(maps,reform(maps.datamaps,nfreqs,npols,ntimes),'datamaps')
                           maps=rep_tag_value(maps,reform(maps.errmaps,nfreqs,npols,ntimes),'errmaps')
                         endelse

                      maxfreq=nfreqs-1
                      maxtime=ntimes-1
                      maxpol=npols-1
                      state.nx=nx
                      state.ny=ny
                      state.ntimes=ntimes
                      state.nfreqs=nfreqs
                      state.npols=npols
                      
                      names=tag_names(maps)
                      validmaps=bytarr(n_tags(maps))
                      for i=0, n_tags(maps)-1 do validmaps[i]=valid_map(maps.(i))
                      names=names[where(validmaps)]
                      mapsize=lonarr(n_elements(names))
                      for i=0,n_elements(names)-1 do mapsize[i] = (size(maps.(i)))[0]
                      mapnames=names[where(mapsize gt 1)]
                      mapnames=mapnames[sort(mapnames)]
                      allparnames=names[where(mapsize eq 1)] 
                      errparnames=allparnames[where(strmid(allparnames,0,3) eq 'ERR')]
                      errparnames=str_replace(errparnames,'ERR','err')
                      parnames=strmid(errparnames,3)
                   
                      idx=sort(parnames)
                      parnames=parnames[idx]
                      errparnames=errparnames[idx]
                      pnames=strarr(2*n_elements(parnames))
                      
                      for i=0, n_elements(parnames)-1 do begin
                        pnames[2*i]=parnames[i]
                        pnames[2*i+1]=errparnames[i]
                      endfor
                      
                      paridx=where(names eq 'CHISQR' or names eq 'CHSQ',count)
                      if count eq 1 then  pnames=[pnames,names[paridx],'RESIDUAL']
                      
                      ptr_free,state.pmaps
                      state.pmaps=ptr_new(temporary(maps))
                      freq=reform((*state.pmaps).datamaps[*,0,0].freq)
                      time=reform((*state.pmaps).datamaps[0,0,*].time)
                      stokes=reform((*state.pmaps).datamaps[0,*,0].stokes)
                      xrange=get_map_xrange((*state.pmaps).datamaps[0])
                      dx=((*state.pmaps).datamaps[0,0]).dx
                      xpix=xrange[0]+findgen(nx)*dx
                      yrange=get_map_yrange((*state.pmaps).datamaps[0])
                      dy=((*state.pmaps).datamaps[0]).dy
                      ypix=yrange[0]+findgen(ny)*dy
                      state.ppd_data_xrange=xrange
                      state.ppd_data_yrange=yrange
                      widget_control,state.wfreq, set_slider_max=maxfreq,set_value=0,set_uvalue=freq,sensitive=1
                      widget_control,state.wpol, set_value=(state.npols eq 1)?stokes:[stokes[0]+'+'+stokes[1],stokes],sensitive=1
                      widget_control,state.wtime, set_slider_max=maxtime,set_value=0,set_uvalue=time,sensitive=1
                      widget_control,state.wx,set_value=0,set_uvalue=xpix
                      widget_control,widget_info(state.wx,/child),/sensitive
                      widget_control,state.wy,set_value=0,set_uvalue=ypix
                      widget_control,widget_info(state.wy,/child),/sensitive
                      widget_control,widget_info(state.wx,/child),get_uvalue=obj_wx
                      obj_wx->SetProperty,max=nx-1
                      widget_control,widget_info(state.wy,/child),get_uvalue=obj_wy
                      obj_wy->SetProperty,max=ny-1
                      
                      widget_control,state.wmaplist, set_value=mapnames
                      widget_control,state.wparmlist, set_value=pnames
                      widget_control,state.wparmlist, set_uvalue=dblarr(2,n_elements(pnames))
                      state.nfreqs=nfreqs
                      state.npols=npols
                      state.ntimes=ntimes
                      state.nx=nx
                      state.ny=ny
                      state.lock=1
                      if ~valid_map(refmap) then if tag_exist(*state.pmaps,'refmap') then refmap=(*state.pmaps).refmap
                      if valid_map(refmap) then begin
                        refmaps=obj_new('map')
                        refmaps->set,2,map=refmap
                        widget_control,state.wmapref,set_value=['Reference: Data', 'Reference: Parameter',refmap.id],set_uvalue=refmaps
                      endif
                      draw=1
                     endif
                  endif
                 endif
                end
   state.wImportFitList: begin
                           maps=gsfit_log2map(header=header)
                           if tag_exist(header,'refmap') then refmap=header.refmap
                           goto,opencube
                         end
                         
   state.wSaveMaps:begin
                           file=dialog_pickfile(title='Select a filename to save the fit map structure',filter='*.sav',/overwrite,/write)
                           if file ne '' then begin
                              maps=*state.pmaps
                              save,maps,file=file
                           endif
                         end                      
                         
   state.wRefMap:begin
                   files=dialog_pickfile(title='Please select one more more files containg maps saved as IDL map structure, IDL objects, or fits',filter=['*.sav','*.map','*.f*s'],/must_exist,/multiple)
                   files=files[sort(files)]
                   FOR idx=0, n_elements(files)-1 DO BEGIN
                     file=files[idx]
                     if file ne '' then begin
                       catch, error_stat
                       if error_stat ne 0 then begin
                         catch, /cancel
                         gx_fits2map,file,map
                         goto, got_a_map
                       end
                       osav=obj_new('idl_savefile',file)
                       names=osav->names()
                       valid=0
                       for i=0,n_elements(names)-1 do begin
                           osav->restore,names[i];,/RELAXED_STRUCTURE_ASSIGNMENT
                           e=execute('result=size('+names[i]+',/tname)')
                           if (result eq 'STRUCT') or (result eq 'OBJREF') then begin
                             e=execute('m=temporary('+names[i]+')')
                             if valid_map(m) then map=temporary(m)
                           endif
                       endfor
                       got_a_map:
                         if ~(size(map,/tname) eq 'STRUCT' or size(map,/tname) eq 'OBJREF') then begin
                           answ=dialog_message('Unexpected file content!',/error)
                         endif else begin
                          widget_control,state.wmapref,get_uvalue=refmaps
                          if ~obj_isa(refmaps,'map') then refmaps=obj_new('map')
                            case size(map,/tname) of
                              'STRUCT': begin
                                         for k=0,n_elements(map)-1 do begin
                                          if valid_map(map[k]) then refmaps->set,refmaps->get(/count),map=map[k]
                                         endfor
                                        end
                              'OBJREF': begin
                                          for k=0,map->get(/count)-1 do begin
                                            if valid_map(map->get(k,/map)) then refmaps->set,refmaps->get(/count),map=map->get(k,/map)
                                          endfor
                                        end
                              else:
                            endcase
                            ids=['Reference: Data', 'Reference: Parameter']
                            for k=0,refmaps->Get(/count)-1 do ids=[ids,refmaps->Get(k,/id)]
                            widget_control,state.wmapref,set_uvalue=refmaps,set_value=ids,set_droplist_select=refmaps->Get(/count)-1
                            draw=1
                          endelse
                       endif
                    ENDFOR   
                 end                      
   state.wMapRef: draw=1 
   state.wParRef: draw=1
   state.wRefmapOptions.Show:draw=1
   state.wRefmapOptions.Order:draw=event.select
   state.wRefmapOptions.level:draw=1
   
   state.wMouse.Cursor: begin
                          state.cursor_on=event.select
                          widget_control,event.id,set_value=gx_bitmap(filepath(event.select?'scale_active.bmp':'scale.bmp', subdirectory=subdirectory))
                        end
   state.wMouse.RROI: begin
                          state.rroi_on=event.select
                          widget_control,event.id,set_value=gx_bitmap(filepath(event.select?'rectangl_active.bmp':'rectangl.bmp', subdirectory=subdirectory))
                       end
   state.wMouse.FROI: begin
                          state.froi_on=event.select
                          widget_control,event.id,set_value=gx_bitmap(filepath(event.select?'freepoly_active.bmp':'freepoly.bmp', subdirectory=subdirectory))
                      end  
   state.wMouse.PROI: begin
                          state.proi_on=event.select
                          widget_control,event.id,set_value=gx_bitmap(filepath(event.select?'segpoly_active.bmp':'segpoly.bmp', subdirectory=subdirectory))
                       end     
   state.wRefROI: begin             
                     widget_control,event.id,get_uvalue=roi     
                     state.wHist.xroi->Remove,/all
                     state.wHist.yroi->Remove,/all
                     state.wHist.xroi->add,roi.x,/extract
                     state.wHist.yroi->add,roi.y,/extract
                     draw=1
                  end                                                                           
   
   state.wPNG:gsfitview2png,state
   state.wHelp: begin
                 help='http://www.ovsa.njit.edu/wiki/index.php/GSFITVIEW_Help'
                 if !version.os_family eq 'Windows' then spawn,'start /max '+help else answ=dialog_message(' For help, please open ' +help+' in your preffred browser.')    
                end                    
                 
   else:
  endcase
  widget_control,widget_info(event.top,Find_By_Uname='STATEBASE'),set_uvalue=state
  gsfitview_draw,state,draw=draw
  widget_control,widget_info(event.top,Find_By_Uname='STATEBASE'),set_uvalue=state
end

pro gsfitview_display_statistics,state,save=save
 if ~ptr_valid(state.pmaps) then return
 charsize=1.2
 charthick=2
 
 time=reform((*state.pmaps).datamaps[0,0,*].time)
 widget_control,state.wtime,get_value=time_idx
 pol_idx=(widget_info(state.wpol,/droplist_select)-1)>0
 widget_control,state.wparmlist,get_value=parm_names,get_uvalue=parm_ranges
 pidx=widget_info(state.wparmlist,/DROPLIST_SELECT)
 widget_control,state.wparmlist,get_value=parm_list
 parm_name=parm_list[pidx]
 tag_names=tag_names((*state.pmaps))
 parm_index=where(strupcase(tag_names) eq strupcase(parm_name))
 errparm_index=where(strupcase(tag_names) eq strupcase('ERR'+parm_name))

  if n_elements(parm_ranges) eq 0 then parm_ranges=dblarr(2,n_elements(parm_names))
  if parm_ranges[0,pidx] eq parm_ranges[1,pidx] then begin
    parm=(((*state.pmaps).(parm_index))).data
    parm=parm[where(parm gt 0)]
    pmin=min(parm,/nan,max=pmax)
    parm_ranges[*,pidx]=[pmin,pmax]
    widget_control,state.wparmlist,set_uvalue=parm_ranges
  endif
 range=parm_ranges[*,pidx]
 widget_control,state.wHist.range, set_value=range
 widget_control,state.wHist.bins, get_value=nbins
 widget_control,state.wHist.check, get_value=check
 widget_control,state.wHistView, get_value=HistView
 widget_control,state.wPlotView, get_value=PlotView
 widget_control,state.wROISum, get_value=ROISum
 ROISum=ROISum[0]
 logbins=check[1]
 loghist=check[2]
 over2d=check[3]
 colapse=check[4]

 h=lonarr(nbins,state.ntimes)

 
 if state.whist.xroi.Count() le 1 then begin
  ij=lindgen(state.nx*state.ny)
 endif else begin
  widget_control,state.wx,get_uvalue=xpix
  widget_control,state.wy,get_uvalue=ypix
  widget_control,state.wHist.check,get_value=check
  xroi=state.whist.xroi.ToArray()
  yroi=state.whist.yroi.ToArray()
  ij=polyfillv((xroi-xpix[0])/(xpix[1]-xpix[0]),(yroi-ypix[0])/(ypix[1]-ypix[0]),state.nx,state.ny)
  if check[0] eq 1 then begin
    data=bytarr(state.nx,state.ny)
    data[ij]=1
    ij=where(data eq 0)
  endif
 end
 
 if n_elements(ij) lt 1 then ij=lindgen(state.nx*state.ny)

 sum_err=(sum=(med_sum_err=(med_sum=(med_err=(med=(weighted_mean_sum_err=(weighted_mean_sum=(weighted_mean=(weighted_mean_err=(dblarr(state.ntimes)*!values.f_nan))))))))))
 
 for i=0,state.ntimes-1 do begin
   parmap=((*state.pmaps).(parm_index))[i]
   parm=double(parmap.data)  
   parm=parm[ij]
   if errparm_index[0] ge 0 then begin
     errparmap=((*state.pmaps).(errparm_index))[i]
     errparm=double(errparmap.data)
     errparm=errparm[ij]
   endif else begin
    errparm=parm*0+1
   endelse
   widget_control,state.wTimeProfileOptions,get_value=objTimePlotOptions
   objTimePlotOptions->GetProperty,yrange=pyrange
   ;good=where((parm gt 0) and (finite(parm) eq 1),count ) 
   good=where((parm ge range[0]) and (parm le range[1]) and (finite(parm) eq 1),count )
   if count gt 0 then begin
    parm=parm[good]
    errparm=errparm[good]
    
    sum[i]=total(parm,/double)
    sum_err[i]=total(errparm,/double)
   
    weights = total(1D / errparm^2,/double)
    weighted_err = sqrt(1D / weights)
    
    weighted_mean[i] = total(1D * parm/ errparm^2,/double) / weights
    weighted_mean_err[i] = weighted_err
    
    weighted_mean_sum[i]= weighted_mean[i]*count
    weighted_mean_sum_err[i]= weighted_mean_err[i]*count
    
    med[i]=median(parm)
    med_err[i]=median(abs(parm-median(parm)))
    
    med_sum[i]= med[i]*count
    med_sum_err[i]= med_err[i]*count
    
 
    if logbins then h[*,i]=histogram(alog10(parm),min=alog10(range[0]),max=alog10(range[1]),nbins=nbins,loc=loc) $
    else h[*,i]=histogram(parm,min=range[0],max=range[1],nbins=nbins,loc=loc)
   end 
 endfor
 

 widget_control,state.wx,get_value=i,get_uvalue=xpix
 widget_control,state.wy,get_value=j,get_uvalue=ypix
 selection=(state.whist.xroi.Count() le 1)?'FOV':(check[0] eq 1)?'Out of ROI':'ROI'
 
 case PlotView of
   0:begin
    case ROISum of
      0:begin
         ;PIXEL
         lightcurve=((*state.pmaps).(parm_index)).data
         lc=lightcurve[i,j,*]
         if errparm_index[0] gt 0 then begin
           errlightcurve=((*state.pmaps).(errparm_index)).data
           errlc=errlightcurve[i,j,*]
         endif else errlc=lc*0
         title='Selected Pixel Lightcurve'
        end 
      else: begin
             lc=sum
             errlc=sum_err
             title=selection+ 'Sum'
            end  
      endcase       
     end
   1:begin
     ;Weighted Mean
     lc=(~ROISum)?weighted_mean:weighted_mean_sum
     errlc=(~ROISum)?weighted_mean_err:weighted_mean_sum_err
     title=selection+((~ROISum)?' Weighted Mean':' Weighted Mean x Npix')
   end
   2:begin
     ;Median
     lc=(~ROISum)?med:med_sum
     errlc=(~ROISum)?med_err:med_sum_err
     title=selection+((~ROISum)?' Median':' Median x Npix')
   end
   else:
 endcase
 
 if n_elements(loc) eq 0 then begin
   loc=lindgen(nbins)
   parm_name='dummy index (no valid data)'
 endif
 
 if min(loc) eq max(loc) then begin
  h[0,*]=0
  h[nbins-1,*]=0
  loc[0]=loc[0]-1
  loc[nbins-1]=loc[nbins-1]+1
 endif
 
 loc=logbins?10^loc:loc
 xtitle=parm_name

 ytitle=colapse?'Counts':'Time Frame'
 
  widget_control,state.wHist.plot,get_value=w
  wset,w
  !p.multi=0
 

  
  if HistView eq 0 then begin
    if keyword_set(colapse) then begin
      plot,loc,total(h,2)>1,/xsty,xtitle=xtitle,ytitle=ytitle,ylog=loghist,psym=10,xlog=logbins
    endif else begin
     spectro_plot,transpose(h),anytim(time),loc,/xsty,/ysty,ytitle=xtitle,xtitle='Time',ylog=logbins,zlog=loghist,color=255,$
        title=selection+' Histograms',charsize=charsize,charthick=charthick
      if over2d then begin
        outplot,time,lc,thick=1,psym=2
        uterrplot,time,lc-errlc,lc+errlc,thick=1
      end
      outplot,time[[time_idx,time_idx]],logbins?10^!y.crange:!y.crange,linesty=2,color=250,thick=3
    endelse
   endif else begin
      utplot,time,lc,thick=1,psym=2,/xsty,charsize=charsize,charthick=charthick,ylog=loghist,ytitle=xtitle,title=title,yrange=range
      uterrplot,time,lc-errlc,lc+errlc,thick=1
      outplot,time[[time_idx,time_idx]],loghist?10^!y.crange:!y.crange,linesty=2,color=250,thick=3
  endelse


 if keyword_set(save) then begin
   file=dialog_pickfile(file='gsfitview_'+parm_name+'_hist.sav',DEFAULT_EXTENSION='sav',$
     filter='*.sav',title='Please choose a filename to save histogram data',/write )
   if file ne ''  then begin
    data_range=range
    parmap=((*state.pmaps).(parm_index))
    xroi=state.whist.xroi->ToArray()
    yroi=state.whist.yroi->ToArray()
    save,file,h,loc,ij,data_range,xroi,yroi,parmap,time,file=file
   endif
 endif
end


pro gsfitview_draw,state, draw=draw,_extra=_extra
 if ~ptr_valid(state.pmaps) or ~keyword_set(draw) then return
 charsize=1.2
 charthick=2
 geometry=widget_info(state.wDataMap,/geometry)
 sz=size((*state.pmaps).datamaps.data)
 widget_control,state.wdatamap,get_value=wdatamap
 widget_control,state.wparmap,get_value=wparmap
 widget_control,state.wspectrum,get_value=wspectrum
 widget_control,state.wtimeplot,get_value=wtimeplot
 widget_control,state.wtime,get_value=time_idx
 widget_control,state.wfreq,get_value=freq_idx
 pol_idx=widget_info(state.wpol,/droplist_select)
 widget_control,state.wx,get_value=i,get_uvalue=xpix
 widget_control,state.wy,get_value=j,get_uvalue=ypix
 map_index=widget_info(state.wmaplist,/DROPLIST_SELECT)
 widget_control,state.wmaplist,get_value=map_list
 map_name=map_list[map_index]
 parm_index=widget_info(state.wparmlist,/DROPLIST_SELECT)
 widget_control,state.wparmlist,get_value=parm_list
 parm_name=parm_list[parm_index]
 tag_names=tag_names((*state.pmaps))
 map_index=where(strupcase(tag_names) eq strupcase(map_name))
 parm_index=where(strupcase(tag_names) eq strupcase(parm_name))
 errparm_index=where(strupcase(tag_names) eq strupcase('ERR'+parm_name))
 freq=(*state.pmaps).datamaps[*,0,0].freq
 time=reform((*state.pmaps).datamaps[0,0,*].time)
; displaymap=((*state.pmaps).(map_index))[freq_idx,time_idx]
; parmap=((*state.pmaps).(parm_index))[time_idx]
 pol=reform((*state.pmaps).datamaps[0,*,0].stokes)
 nfreqs=state.nfreqs
 ntimes=state.ntimes
 npols=state.npols

 if npols eq 2 then begin
      if pol_idx eq 0 then begin
        displaymap=((*state.pmaps).(map_index))[freq_idx, 0,time_idx]
        splitid=strsplit(displaymap.id,/extract)
        id=splitid[0]+' '+((*state.pmaps).(map_index))[freq_idx, 0,time_idx].stokes+'+'+((*state.pmaps).(map_index))[freq_idx, 1,time_idx].stokes
        if n_elements(splitid) gt 2 then id=strjoin([id,' ',splitid[2:*]])
        displaymap.id=id
        data_spectrum=(((*state.pmaps).datamaps)[*, 0,time_idx]).data+(((*state.pmaps).datamaps)[*, 1,time_idx]).data
        fit_spectrum=(((*state.pmaps).fitmaps)[*, 0,time_idx]).data+(((*state.pmaps).fitmaps)[*, 1,time_idx]).data
        err_spectrum=(((*state.pmaps).errmaps)[*, 0,time_idx]).data+(((*state.pmaps).errmaps)[*, 1,time_idx]).data
      endif else begin
        displaymap=((*state.pmaps).(map_index))[freq_idx, pol_idx-1,time_idx]
        data_spectrum=(((*state.pmaps).datamaps)[*, pol_idx-1,time_idx]).data
        fit_spectrum=(((*state.pmaps).fitmaps)[*, pol_idx-1,time_idx]).data
        err_spectrum=(((*state.pmaps).errmaps)[*, pol_idx-1,time_idx]).data
      endelse
    endif else begin
      displaymap=((*state.pmaps).(map_index))[freq_idx, pol_idx,time_idx]
      data_spectrum=(((*state.pmaps).datamaps)[*, pol_idx,time_idx]).data
      fit_spectrum=(((*state.pmaps).fitmaps)[*, pol_idx,time_idx]).data
      err_spectrum=(((*state.pmaps).errmaps)[*, pol_idx,time_idx]).data
    endelse
 parmap=((*state.pmaps).(parm_index))[time_idx]

 widget_control,state.wfreqlabel,set_value=strcompress(string(freq[freq_idx],format="(f5.2,' GHz ')"))+strcompress(string(freq_idx,format="(' [',i3,']')"),/rem)
 widget_control,state.wtimelabel,set_value=time[time_idx]+' '+strcompress(string(time_idx,format="(' [',i3,']')"),/rem)
  rgb_curr=bytarr(3,256)
  tvlct,rgb_curr,/get
  psave=!p
  !p.multi=0
  wset,wdatamap
  widget_control,state.wmapref,get_uvalue=refmaps
  refmap_idx=widget_info(state.wmapref,/droplist_select)
  case refmap_idx of
    0:refmap=displaymap
    1:refmap=parmap
    else: begin 
           refmap=refmaps->get(refmap_idx-2,/map)
           if strmid(refmap.id,0,5) ne 'EOVSA' then begin
             widget_control,state.wparref,get_value=xyshift
             xshift=xyshift[0]
             yshift=xyshift[1]
           end
          end 
  endcase
  xrange=state.ppd_data_xrange
  yrange=state.ppd_data_yrange
  widget_control,state.wRefMapOptions.Show,get_value=showrefmap
  widget_control,state.wRefMapOptions.level,get_value=level
  widget_control,state.wRefMapOptions.order,get_value=contour
  
  
  if keyword_set(showrefmap) then begin
     if keyword_set(contour) then begin
        plot_map,displaymap,title=displaymap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,charsize=charsize,charthick=charthick
        plot_map,refmap,/over,levels=level,/per,thick=3,color=255,xshift=xshift,yshift=yshift
     endif else begin
        plot_map,refmap,title=refmap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,xshift=xshift,yshift=yshift,charsize=charsize,charthick=charthick
        plot_map,displaymap,/over,levels=level,/per,thick=3,color=255
    endelse
  endif else  plot_map,displaymap,title=displaymap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,charsize=charsize,charthick=charthick
  
  oplot,xpix[[i,i]],!y.crange,linesty=2,color=250,thick=3
  oplot,!x.crange,ypix[[j,j]],linesty=2,color=250,thick=3
  widget_control,state.wHist.check,get_value=check
  if ~state.wHist.xroi.IsEmpty() then begin
    plots,state.wHist.xroi.ToArray(),state.wHist.yroi.ToArray(),color=250,thick=3
  endif
  g={x:!x,y:!y,z:!z,p:!p}
  widget_control,state.wdatamap,set_uvalue=g
  widget_control,state.wparmap,set_uvalue=g

  wset,wparmap
  parmap.data=parmap.data>0
  widget_control,state.wTimeProfileOptions,get_value=objTimePlotOptions
  objTimePlotOptions->GetProperty,range=range,yrange=data_range,ylog=log_scale
  if strupcase(range) eq 'MANUAL' then begin
    dmin=data_range[0]
    dmax=data_range[1]
  endif
  if keyword_set(showrefmap) then begin
    if keyword_set(contour) then begin
      plot_map,parmap,title=parmap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,charsize=charsize,charthick=charthick,dmin=dmin,dmax=dmax,log_scale=log_scale
      plot_map,refmap,/over,levels=level,/per,thick=3,color=255,xshift=xshift,yshift=yshift
      frontmap=refmap
    endif else begin
      plot_map,refmap,title=refmap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,xshift=xshift,yshift=yshift,charsize=charsize,charthick=charthick
      plot_map,parmap,/over,levels=level,/per,thick=3,color=255
      frontmap=parmap
    endelse
  endif else  plot_map,parmap,title=parmap.id,grid=10,/limb,/cbar,xrange=xrange, yrange=yrange,charsize=charsize,charthick=charthick,dmin=dmin,dmax=dmax,log_scale=log_scale
  
  oplot,xpix[[i,i]],!y.crange,linesty=2,color=250,thick=3
  oplot,!x.crange,ypix[[j,j]],linesty=2,color=250,thick=3
  if ~state.wHist.xroi.IsEmpty() then plots,state.wHist.xroi.ToArray(),state.wHist.yroi.ToArray(),color=250,thick=3
  
  if keyword_set(showrefmap) then begin
        get_map_coord,frontmap,xp,yp
        contour,frontmap.data,xp,yp,levels=level*max(frontmap.data)/100,path_xy=xy,path_info=info,/PATH_DATA_COORDS
        m=max(info.n,k)
        FOR k = 0, (N_ELEMENTS(info) - 1 ) DO BEGIN 
          S = [INDGEN(info(k).N), 0]
          xroi=(k eq 0)? reform(xy[0,INFO(k).OFFSET + S ]):[xroi,reform(xy[0,INFO(k).OFFSET + S ])]
          yroi=(k eq 0)? reform(xy[1,INFO(k).OFFSET + S ]):[yroi,reform(xy[1,INFO(k).OFFSET + S ])]
        end  
        widget_control,state.wRefROI,set_uvalue={x:xroi,y:yroi}   
  endif else  widget_control,state.wRefROI,set_uvalue={x:displaymap.xc,y:displaymap.yc}  
  
  if draw eq 1 then begin
    wset,wspectrum
    sz=size(data_spectrum)
    if i lt sz[1] and j lt sz[2] then begin
      if n_elements(range) gt 0 then dummy=temporary(range)
      if n_elements(pxrange) gt 0 then dummy=temporary(pxrange)
      if n_elements(pyrange) gt 0 then dummy=temporary(pyrange)
      if n_elements(xlog) gt 0 then dummy=temporary(xlog)
      if n_elements(ylog) gt 0 then dummy=temporary(ylog)
      widget_control,state.wSpectralPlotOptions,get_value=objSpectralPlotOptions
      objSpectralPlotOptions->GetProperty,range=range,xrange=pxrange,yrange=pyrange,xlog=xlog,ylog=ylog,/xsty,/ysty
      good=where(data_spectrum[i,j,*] gt 0)>0
      if range eq 'Auto' then begin
        pyrange=minmax(data_spectrum[i,j,good])
        pxrange=[1,20]
      end
      plot,freq,data_spectrum[i,j,*],xlog=xlog,ylog=ylog,xrange=pxrange,yrange=pyrange,psym=2,$
        xtitle='Frequency (GHz)',ytitle='Flux density [sfu/pixel]',title='Spectral Fit',ymargin=[6,6],/xsty,/ysty,charsize=charsize,charthick=charthick
      oploterr, freq, data_spectrum[i,j,*], err_spectrum[i,j,*]*2, psym=3;, hatlength=2, errcolor=255 
      oplot,freq,fit_spectrum[i,j,*],color=150,thick=3
      oplot,freq[[freq_idx,freq_idx]],10^!y.crange,linesty=2,color=250,thick=3
      if range eq 'Auto' then objSpectralPlotOptions->SetProperty,xrange=keyword_set(xlog)?10^!x.crange:!x.crange, yrange=keyword_set(ylog)?10^!y.crange:!y.crange
    endif else erase,0
    
    
    wset,wtimeplot
     if i lt sz[1] and j lt sz[2] then begin
      if n_elements(range) gt 0 then dummy=temporary(range)
      if n_elements(pxrange) gt 0 then dummy=temporary(pxrange)
      if n_elements(pyrange) gt 0 then dummy=temporary(pyrange)
      if n_elements(xlog) gt 0 then dummy=temporary(xlog)
      if n_elements(ylog) gt 0 then dummy=temporary(ylog)
      if n_elements(pyrange) gt 0 then dummy=temporary(pyrange)
      widget_control,state.wTimeProfileOptions,get_value=objTimePlotOptions
      objTimePlotOptions->GetProperty,range=range,xrange=pxrange,yrange=pyrange,xlog=xlog,ylog=ylog
  
      lightcurve=((*state.pmaps).(parm_index)).data
      if errparm_index[0] gt 0 then errlightcurve=((*state.pmaps).(errparm_index)).data
      
      if range eq 'Auto' then begin
        pyrange=minmax(lightcurve[i,j,*])>0 
      end
      
      lc=lightcurve[i,j,*]
      if errparm_index[0] gt 0 then errlc=errlightcurve[i,j,*]
      CATCH, Error_status
      IF Error_status NE 0 THEN BEGIN
        PRINT, 'Error index: ', Error_status
        PRINT, 'Error message: ', !ERROR_STATE.MSG
        lc[*]=0
        if errparm_index[0] gt 0 then errlc[*]=0
        dummy=temporary(pyrange)
        CATCH, /CANCEL
      ENDIF
    
      utplot,time,lc,ytitle=parmap.id,psym=3,title=parmap.id+' Evolution',/xsty,/ysty,ymargin=[6,6],ylog=ylog,xlog=xlog,xrange=pxrange,yrange=pyrange,charsize=charsize,charthick=charthick
      outplot,time,lc,color=150,thick=3,psym=2
      if errparm_index[0] gt 0 then begin
       uterrplot,time,lc-errlc,lc+errlc
      endif
      outplot,time[[time_idx,time_idx]],keyword_set(ylog)?10^!y.crange:!y.crange,linesty=2,color=250,thick=3
      good=where(lc,count)
      if count gt 0 then begin
        mom=moment(lc[good],mean=mean,sdev=sdev,/nan,/double)
         outplot,minmax(time),mean[[0,0]]
         outplot,minmax(time),mean+sdev[[0,0]],linesty=1
         outplot,minmax(time),mean-sdev[[0,0]],linesty=1
      endif
      
      if range eq 'Auto' then objTimePlotOptions->SetProperty,xrange=keyword_set(xlog)?10^!x.crange:!x.crange, yrange=keyword_set(ylog)?10^!y.crange:!y.crange
    endif else erase,0 
  end
  
  gsfitview_display_statistics,state,_extra=_extra
  tvlct,rgb_curr
  !p=psave
  
  winfo=widget_info(state.wbase,find_by_uname='info')

  cmdot = STRING([183B]) ; Middle dot
  cbullet = STRING([149B]) ; Bullet
  ctab = STRING([9B]) ; tab
  ccr = STRING(13B) ; Carriage Return
  clf = STRING([10B]) ; line feed
  pm= STRING([177B])

  names=tag_names(*state.pmaps)
  parsize=lonarr(n_elements(names))
  for k=0,n_elements(names)-1 do parsize[k] = (size((*state.pmaps).(k)))[0]
  parnames=names[where(parsize eq 1)]
  parnames=parnames[sort(parnames)]
  errnames=parnames[where(strmid(parnames,0,3) eq 'ERR')]
  parnames=strmid(errnames,3)  
  paridx=where(names eq 'CHISQR' or names eq 'CHSQ')
  
  if i lt sz[1] and j lt sz[2] then begin
    par=((((*state.pmaps).(paridx))[time_idx]).data)[i,j]
    lines=[ 'CHISQR'+ctab+strcompress(string(par,format="('=', g10.3)")),'']
    widget_control,state.wxlabel,set_value=string(xpix[i],format="('X:',f7.2,'arcsec')")
    widget_control,state.wylabel,set_value=string(ypix[j],format="('Y:',f7.2, 'arcsec')")
    for k=0,n_elements(parnames)-1 do begin
      paridx=where(names eq parnames[k])
      erridx=where(names eq errnames[k])
      par=((((*state.pmaps).(paridx))[time_idx]).data)[i,j]
      err=((((*state.pmaps).(erridx))[time_idx]).data)[i,j]
      case parnames[k] of
        'B':units='Gauss'
        'DELTA':units=''
        'EMIN':units='MeV'
        'EMAX':units='MeV'
        'NRL':units='cm^-3'
        'NTH':units='cm^-3'
        'THETA':units='deg'
        else:units=((((*state.pmaps).(erridx))[time_idx]).dataunits)
      endcase
       LINES=[LINES,parnames[k]+ctab+strcompress(string(par,pm,err,format="('=(',g16.2,a2,g16.2,') ')")+units),'']
    endfor
  endif else lines=''  
  widget_control,winfo,set_value=LINES
end

pro gsfitview2png,state
 if ~ptr_valid(state.pmaps) then return
 widget_control,state.wHist.check, get_value=hcheck
 colapse=hcheck[4]
 widget_control,state.wPNGCheck,get_value=check
 parm_index=widget_info(state.wparmlist,/DROPLIST_SELECT)
 widget_control,state.wparmlist,get_value=parm_list
 parm_name=parm_list[parm_index]
 widget_control,state.wx,get_value=i,get_uvalue=xpix
 widget_control,state.wy,get_value=j,get_uvalue=ypix
 widget_control,state.wfreqlabel,get_value=freq_label
 widget_control,state.wtimelabel,get_value=time_label
 widget_control,state.wdatamap,get_value=wdatamap
 widget_control,state.wparmap,get_value=wparmap
 widget_control,state.wspectrum,get_value=wspectrum
 widget_control,state.wtimeplot,get_value=wtimeplot
 widget_control,state.wHist.plot,get_value=whist
 histname=strlowcase((((state.whist.xroi.Count() le 1)?'FOV':((hcheck[0] eq 1)?'OUTROI':'ROI')))+'hist'+(colapse?'1D':'2D'))
 id=strmid(strreplace(strreplace(strreplace(atime(strmid(time_label,0,20),/y2k,/hxrbs),'/',''),', ','_'),':',''),0,15)+'-gsfit-'
 freq='['+strcompress(strmid(freq_label,0,9),/rem)+']'
 wset,wdatamap
 img_datamap=tvrd(/true)
 wset,wparmap
 img_parmap=tvrd(/true)
 wset,wtimeplot
 img_timeplot=tvrd(/true)
 wset,wspectrum
 img_spectrum=tvrd(/true)
 wset,whist
 img_hist=tvrd(/true)
 names=[freq+'datamap',parm_name+'map','['+strcompress(arr2str(long([i,j])),/rem)+']'+'spectrum','['+strcompress(arr2str(long([i,j])),/rem)+']'+parm_name+'timeplot',parm_name+histname]
 img={datamap:img_datamap,parmap:img_parmap,spectrum:img_spectrum,timeplot:img_timeplot,hist:img_hist}
 idx=where(check[0:4] eq 1,count)
 check[5]=check[4]?0:check[5]
 case count of
  1: begin 
       filename=id+names[idx]+'.png'
       filename=dialog_pickfile(Title='Accept or choose file name to save selected panels as PNG',default='png',filter='*.png',file=filename,/overwrite,/write)
       if filename ne '' then WRITE_PNG,filename, img.(idx)
     end  
  2: begin 
      filename=id+names[idx[0]]+'-'+names[idx[1]]+'.png'
      filename=dialog_pickfile(Title='Accept or choose file name to save selected panels as PNG',default='png',filter='*.png',file=filename,/overwrite,/write)
      if filename ne '' then WRITE_PNG,filename, check[5]?[[[img.(idx[1])]] ,[[img.(idx[0])]]] :[[img.(idx[0])] ,[img.(idx[1])]] 
     end
  3: begin
      filename=id+names[idx[0]]+'-'+names[idx[1]]+'-'+names[idx[2]]+'.png'
      filename=dialog_pickfile(Title='Accept or choose file name to save selected panels as PNG',default='png',filter='*.png',file=filename,/overwrite,/write)
      if filename ne '' then WRITE_PNG,filename, check[5]?[[[img.(idx[2])]] ,[[img.(idx[1])]],[[img.(idx[0])]]] :[[img.(idx[0])] ,[img.(idx[1])],[img.(idx[2])]] 
     end
  else:answ=dialog_message('At least one, but more than 3 panels may be selected at this time to create PNG figures!')
 endcase
end

pro gsfitview,maps
  loadct,39
  gsfitdir=file_dirname((ROUTINE_INFO('gsfitview',/source)).path,/mark)
  
  cd,gsfitdir,curr=cdir
    resolve_routine,'oploterr'
    resolve_routine,'gsfit_log2map',/is_function,/no_recompile
    resolve_routine,'gsfit_log2list',/is_function,/no_recompile
    resolve_routine,'gsfit',/no_recompile
    resolve_routine,'gsfitcp',/no_recompile
    resolve_routine,'gsfit_energy_computation',/no_recompile
    cd,get_logenv('SSW')+'/packages/gx_simulator/util'
    resolve_routine,'gx_plot_label',/no_recompile
    cd,get_logenv('SSW')+'/packages/gx_simulator/support'
    resolve_routine,'tvplot',/no_recompile
  cd,cdir
  
  if !version.os_family eq 'Windows' then set_plot,'win' else set_plot,'x'
  defsysv,'!DEFAULTS',EXISTS=exists
  if not exists then gx_defparms
  device, get_screen_size=scr
  if !version.os_family eq 'Windows' then begin
    if scr[0] lt 3200 then !defaults.font='lucida console*12' else !defaults.font='lucida console*24'
  endif else begin
    if scr[0] lt 3200 then !defaults.font='' else !defaults.font=''
  endelse
  if scr[0] lt 3200 then nb=16 else nb=32
  subdirectory=['resource', 'bitmaps']
  xsize=0.69*scr[1]/2
  main_base= WIDGET_BASE(Title ='GSFITVIEW',/column,UNAME='MAINBASE',/TLB_KILL_REQUEST_EVENTS,TLB_FRAME_ATTR=0,$
  x_scroll_size=0.67*scr[0],y_scroll_size=scr[1]*0.9,/scroll)
  state_base=widget_base(main_base, /column,UNAME='STATEBASE')
  wToolbarBase=widget_base(state_base, /row,/frame,UNAME='TOOLBAR',/toolbar)
  wOpen= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('open.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Upload Fit Map Structure')
  wImportFitList= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('importf.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Import Fit List') 
  wSaveMaps= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('save.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Save Imported Fit Map Structure')    
  wRefmap= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('surface.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Import Reference Map')  
  wPalette = widget_button( wToolbarBase, $
    value=gx_bitmap(filepath('palette.bmp', subdirectory=subdirectory)), $
    /bitmap,tooltip='Change Color Table')  
  
  wCursorBase=widget_base(wToolbarBase,/exclusive,/row)
  wCursor= WIDGET_BUTTON(wCursorBase, VALUE=gx_bitmap(filepath('scale_active.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Cursor',uname='cursor')
  widget_control,wCursor,set_button=1
  wRROI= WIDGET_BUTTON(wCursorBase, VALUE=gx_bitmap(filepath('rectangl.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Rectangular ROI Selection',uname='rroi')  
  wPROI= WIDGET_BUTTON(wCursorBase, VALUE=gx_bitmap(filepath('segpoly.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Free-hand ROI Selection',uname='froi')  
  wFROI= WIDGET_BUTTON(wCursorBase, VALUE=gx_bitmap(filepath('roi.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Free-hand ROI Selection',uname='froi')  
  wRefROI= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('contour.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Set Reference Contour ROI')  
  wROISave= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('export.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Save ROI')  
  wROIOpen= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('importf.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Import ROI')  
  wHistSave= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('save.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Save Histogram Data')
;  wHistPS= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('plot.bmp', subdirectory=subdirectory)),$
;    /bitmap,tooltip='Plot Histogram to PostScript File')
  wPNG= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('window.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Save selected panels to PNG')   

      
  wHelp= WIDGET_BUTTON(wToolbarBase, VALUE=gx_bitmap(filepath('help.bmp', subdirectory=subdirectory)),$
    /bitmap,tooltip='Help')  
;=======================================================================================================================      
  row1_base=widget_base(state_base,/row)
  row1_splitbase=widget_base(row1_base,/row)
  row1_freqbase=widget_base(row1_splitbase,/row)
  row1_polbase=widget_base(row1_splitbase,/row)
;=======================================================================================================================    
  wpolabel=widget_label(row1_polbase,value='Stokes',font=!defaults.font,/align_center,uname='stokeslabel')
  g=widget_info(row1_polbase,/geometry)
  wfreqlabel=widget_label(row1_freqbase,xsize=xsize-g.xsize*1.1,value='Frequency',font=!defaults.font,/align_center,uname='freqlabel')
  wtimelabel=widget_label(row1_base,xsize=xsize,value='Time',font=!defaults.font,/align_center,uname='timelabel')
  wPNGlabel=widget_label(row1_base,xsize=xsize,value='PNG Panel Capture Options',font=!defaults.font,/align_center)
  hist_scale=1.3
  ;wHistLabel=widget_label(row1_base,xsize=xsize*hist_scale,value='Histogram Settings',font=!defaults.font,/align_center);,scr_ysize=1.3*g.scr_ysize)
;=======================================================================================================================    
  row2_base=widget_base(state_base,/row)
  row2_splitbase=widget_base(row2_base,/row)
  row2_freqbase=widget_base(row2_splitbase,/row)
  row2_polbase=widget_base(row2_splitbase,/row)
  row2_timebase=widget_base(row2_base,/row)
;=======================================================================================================================    
  wpol=widget_droplist(row2_polbase,value=['LL+RR','LL','RR'],font=!defaults.font,/align_center,uname='stokes',sensitive=0)
  g=widget_info(row2_polbase,/geometry)
  wfreq=WIDGET_SLIDER(row2_freqbase,xsize=xsize-g.xsize*1.1,max=maxfreq,uvalue='FREQ',font=!defaults.font,/suppress,uname='frequency',sensitive=0)
  wtime=WIDGET_SLIDER(row2_timebase,xsize=xsize,uvalue='TIME',max=maxtime,font=!defaults.font,/suppress,uname='time',sensitive=0)
  wPNGCheck=cw_bgroup(widget_base(row2_base,xsize=xsize*hist_scale,/row,/frame),['Data','Parm', 'Spec','Time','Hist','Vert'],SET_VALUE=0,/nonexclusive,/row,font=!defaults.font)

;=======================================================================================================================    
  row3_base=widget_base(state_base,/row)
;=======================================================================================================================    
  wmaplist=WIDGET_DROPLIST(row3_base,xsize=xsize,value=['Data Maps'],uvalue='Map',font=!defaults.font)
  wparmlist=WIDGET_DROPLIST(row3_base,xsize=xsize,value=['Parameter Maps'],uname='Parm',font=!defaults.font)
  hp_base=widget_base(row3_base,xsize=xsize*hist_scale,/row,/frame)
  wHistView=cw_bgroup(hp_base,['Hist','Plot'],SET_VALUE=0,/exclusive,/row,font=!defaults.font,/frame)
  wPlotView=cw_bgroup(hp_base,['Pix','Mean', 'Med'],SET_VALUE=0,/exclusive,/row,font=!defaults.font,/frame)
  wROISum=cw_bgroup(hp_base,['ROISum'],SET_VALUE=0,/nonexclusive,/row,font=!defaults.font,/frame)

  
;=======================================================================================================================  
  row4_base=widget_base(state_base,/row)
;=======================================================================================================================   
  tmpbase=widget_base(row4_base,xsize=xsize,/row,/frame)
  wMapRefBase1=widget_base(tmpbase)
  wMapRefBase2=widget_base(tmpbase)
  wShowRef=cw_bgroup(wMapRefBase2,'Show',/nonexclusive,set_value=0,font=!defaults.font)
  g=widget_info(wShowRef,/geometry)
  wMapRef=WIDGET_DROPLIST(wMapRefBase1,xsize=xsize-g.scr_xsize,value=['Reference: Data', 'Reference: Parameter'],uvalue='MapRef',font=!defaults.font)


  wRefOptionBase=widget_base(row4_base,xsize=xsize,/row,/frame)
  wRefOrder=cw_bgroup(wRefOptionBase,['Back','Countour'],/row,/exclusive,SET_VALUE=1,font=!defaults.font)
  wRefLevel=cw_objfield(wRefOptionBase,label='Level ',value=10,units='%',inc=10l,type=1l,min=0,max=100,xtextsize=4)
  wHistCheck=cw_bgroup(widget_base(row4_base,xsize=xsize*hist_scale,/row,/frame),['OutROI','LogBins', 'Ylog','Over2D','1D'],SET_VALUE=0,/nonexclusive,/row,font=!defaults.font)

  row5_base=widget_base(state_base,/row)
  wdatamap=WIDGET_DRAW( row5_base,xsize=xsize,ysize=xsize,UNAME='DATAMAP',$
    /button_events, $
    /motion_events, $
    retain=1, $
    graphics_level=1 $
    )  
  wparmap=WIDGET_DRAW(row5_base,xsize=xsize,ysize=xsize,UNAME='PARMAP',$
    /button_events, $
    /motion_events, $
    retain=1, $
    graphics_level=1 $
    )    
    
  wHistPlot=WIDGET_DRAW(row5_base,xsize=xsize*hist_scale,ysize=xsize,UNAME='HISTPLOT',graphics_level=1,retain=1)    
;=======================================================================================================================  
  row6_base=widget_base(state_base,/row)
;=======================================================================================================================    
  wxybase=widget_base(row6_base,xsize=xsize,/row)
  wxbase=widget_base(wxybase,xsize=xsize/2)
  wx=cw_objfield(wxbase,label='Cursor X: ',xtextsize=3,max=xsize-1,min=0,inc=1,font=!defaults.font,uname='cursor_x',sensitive=0)
  wxlabel=widget_info(wx,find_by_uname='_label')
  wybase=widget_base(wxybase,xsize=xsize/2)
  wy=cw_objfield(wybase,label='Cursor Y: ',xtextsize=3,max=xsize-1,min=0,inc=1,font=!defaults.font,uname='cursor_y',sensitive=0)
  wylabel=widget_info(wy,find_by_uname='_label')
  wparref=CW_ObjArray(widget_base(row6_base,xsize=xsize),value=[0,0],font=!defaults.font,/static,names=['Refmaps shift_X:','Refmaps shift_Y:'],unit='"',inc=2,ysize=40)  

  hbase=widget_base(row6_base,xsize=xsize*hist_scale,/row)
  wHistRange=cw_objarray(hbase,/static,value=[0,0],font=!defaults.font,xtextsize=10,names=['Min','Max'])
  wHistBins=cw_objarray(hbase,value=100,xtextsize=5,names='nbins',inc=10,/static)
;=======================================================================================================================
  row7_base=widget_base(state_base,/row)
;=======================================================================================================================      
  wspectrum=WIDGET_DRAW(row7_base,xsize=xsize,ysize=xsize,UNAME='SPECTRUM',$
    retain=1, $
    graphics_level=1 $
    ) 
  wtimeplot=WIDGET_DRAW(row7_base,xsize=xsize,ysize=xsize,UNAME='TIMEPLOT',$
    retain=1, $
    graphics_level=1 $
    ) 
  
  winfobase=widget_base(row7_base,/row,/frame)
  
  plot_options_base=!version.os_family eq 'Windows'?widget_base(winfobase,/column):widget_tab(winfobase)
  
  wSpectralPlotOptions=cw_objPlotOptions(widget_base(plot_options_base,title='Spectral Plot Options'),uname=!version.os_family eq 'Windows'?'Spectral Plot Options':'',/xlog,/ylog)
  widget_control,wSpectralPlotOptions,get_value=objSpectralPlotOptions
  wTimeProfileOptions=cw_objPlotOptions(widget_base(plot_options_base,title='Time Plot Options'),uname=!version.os_family eq 'Windows'?'Time Plot Options':'')
  
  g2=widget_info(plot_options_base,/geometry)
  wInfo=widget_text(winfobase,scr_xsize=xsize*hist_scale-g2.scr_xsize,scr_ysize=xsize,/align_left,uname='info',/scroll)

  if !version.os_family eq 'Windows' then set_plot,'win' else set_plot,'x'                      
  window,/free,/pixmap,xsiz=xsize,ysiz=xsize
  erase,0
  wpixmap=!d.window                        
  WIDGET_CONTROL, /REALIZE, main_base 
  default,nx,100l
  default,ny,100l
  default,nfreqs,100l
  default,npols,2l
  default,ntimes,100l
  default,pmaps,ptr_new()
  state=$
    {nfreqs:nfreqs,$
    npols:npols,$
    ntimes:ntimes,$
    nx:nx,$
    ny:ny,$
    lock:0b,$
    pmaps:pmaps,$
    wbase:main_base,$
    wdatamap:wdatamap,$
    wparmap:wparmap,$
    wmapref:wmapref,$
    wparref:wparref,$
    wspectrum:wspectrum,$
    wtimeplot:wtimeplot,$
    wfreq:wfreq,$
    wx:wx,$
    wy:wy,$
    wmaplist:wmaplist,$
    wpol:wpol,$
    wtime:wtime,$
    wparmlist:wparmlist,$
    wpixmap:wpixmap,$
    wOpen:wOpen,$
    wSaveMaps:wSaveMaps,$
    wImportFitList:wImportFitList,$
    wHelp:wHelp,$
    wfreqlabel:wfreqlabel,$
    wtimelabel:wtimelabel,$
    wxlabel:wxlabel,$
    wylabel:wylabel,$
    wPalette:wPalette,$
    wRefmap:wRefmap,$
    wMouse:{Cursor:wCursor,RROI:wRROI,FROI:wFROI,PROI:wPROI},$
    wHist:{range:wHistRange,bins:wHistBins,check:wHistCheck,plot:wHistPlot,save:wHistSave,xRoi:list(),yRoi:list(),wROIOpen:wROIOpen,wROISave:wROISave},$
    ppd_dev_xrange:[0,0],ppd_dev_yrange:[0,0],$
    ppd_data_xrange:[0.0,0.0],ppd_data_yrange:[0.0,0.0],$
    left_button_down:0, $
    cursor_on:1, $
    froi_on:0, $
    rroi_on:0, $
    proi_on:0, $
    wTimeProfileOptions:wTimeProfileOptions,$
    wSpectralPlotOptions:wSpectralPlotOptions,$
    wRefmapOptions:{Show:wShowRef, Order:wRefOrder, level:wRefLevel},$
    wRefROI: wRefROI, $
    wPNGCheck:wPNGCheck, $
    wPNG:wPNG,$
    wHistView:wHistView,$
    wPlotView:wPlotView, $
    wROISum:wROISum $
    }
  widget_control,state_base,set_uvalue=state  
  XMANAGER, 'gsfitview', main_base ,/no_block
  if n_elements(maps) gt 0 then widget_control,main_base,send_event={id:0l,top:0l,handler:0l,maps:maps}
  gsfitview_draw,state
end