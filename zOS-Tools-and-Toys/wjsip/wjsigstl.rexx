/* REXX ***************************************************************
**                                                                   **
** Copyright 2013-2020 IBM Corp.                                     **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
**                                                                   **
**********************************************************************/

/**********************************************************************/
/* WJSIGSTL:  show stale vnodes                                       */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigstl                                                        */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  10/04/13                            */
/*  Change activity:                                                  */
/*                                                                    */
/**********************************************************************/
/* REXX */
/* Prolog for WJSID diagnostic skeletons */
if 0 then
   do
   novalue:
     say 'uninitialized variable in line' sigl
     say sourceline(sigl)
   halt:
     exit 0
  end
signal on novalue
signal on halt
call syscalls 'ON'
parse arg parm
if parm='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
numeric digits 12
call setglobals

parm=''
/* REXX */
/**********************************************************************/
/* WJSIGSTL:  show stale vnodes                                       */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigstl                                                        */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  10/04/13                            */
/*  Change activity:                                                  */
/*                                                                    */
/**********************************************************************/
parse arg stack
if stack='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end

count=0
gfs@=getstor('1008',4,kasid,fds)
do while gfs@<>0
   ln=gfs@
   gfsname=strip(x2c(getstor(xadd(gfs@,'18'),8,kasid,fds)))
   vfs@=getstor(xadd(gfs@,'0c'),4,kasid,fds)
   gfs@=getstor(xadd(gfs@,'08'),4,kasid,fds)

   do while vfs@<>0
      vfsname=x2c(getstor(xadd(vfs@,'38'),44,kasid,fds))
      vnod@=getstor(xadd(vfs@,'2c'),4,kasid,fds)
      flags=x2c(getstor(xadd(vfs@,'34'),4,kasid,fds))
      call setflags
      /*   if vfsavail=0 & vfsdead=0 & vfsperm=0 then */
         do while vnod@<>0
            flgs3=x2b(getstor(xadd(vnod@,'3B'),1,kasid,fds))
            stale=substr(flgs3,4,1)
            if stale then
               do
               vnodname=getstor(xadd(vnod@,'A0'),16,kasid,fds)
               vnodname=translate(x2c(vnodname),' ','00'x)
               vnodras=getstor(xadd(vnod@,'E4'),3,kasid,fds)
               if count=0 then
                  call say 'vnodras vfs@     vnode@   name in vnode    file system name'
               call say ' 'vnodras vfs@ vnod@ vnodname vfsname
               count=count+1
               end
            vnod@=getstor(xadd(vnod@,'88'),4,kasid,fds)
         end
      vfs@=getstor(xadd(vfs@,'08'),4,kasid,fds)
   end
end
if count=0 then
   call say 'no stale vnodes found'

return

setflags:
   sfmsg=''
   ro=bitand('80000000'x,flags)=='80000000'x
   rw=bitand('40000000'x,flags)=='40000000'x
   unmnt=bitand('10000000'x,flags)=='10000000'x
   vfsavail=bitand('00800000'x,flags)=='00800000'x
   vfsdead=bitand('00400000'x,flags)=='00400000'x
   quiesced=bitand('00040000'x,flags)=='00040000'x
   vfsperm=bitand('00004000'x,flags)=='00004000'x
   client=bitand('00000002'x,flags)=='00000002'x
   if ro then sfmsg='R/O'
   if rw then sfmsg='R/W'
   if client then sfmsg=sfmsg 'Client'
     else         sfmsg=sfmsg 'Local '
   if unmnt then sfmsg=sfmsg 'Unmount'
   if quiesced then sfmsg=sfmsg 'Quiesced'
   return sfmsg
/* REXX */
/**********************************************************************/
/*       general utilities                                            */
/*                                                                    */
/* setglobals                                                         */
/*    alet. cvt, ecvt, ocvt, kasid, fds, asvt, ascb, assb, stok, ocve */
/*    symx                                                            */
/* getsysnames                                                        */
/* getstor                                                            */
/* extr                                                               */
/* say                                                                */
/* gettod                                                             */
/* toddiff                                                            */
/* e2tod                                                              */
/* tod2e                                                              */
/* xadd                                                               */
/* dump                                                               */
/* fixaddr                                                            */
/*                                                                    */
/**********************************************************************/
parse arg parm
if parm='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
setglobals:
   address mvs 'subcom IPCS'
   if rc then
      do
      ipcs=0
      symx=''
      end
    else
      do
      ipcs=1
      address ipcs 'evalsym x rexx(address(symx))'
      end
   alet.=''
   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   z4='00000000'x
   z1='00'x
   cvt=getstor(10,4,1)
   ecvt=getstor(d2x(x2d(cvt)+cvtecvt),4,1)
   ocvt=fixaddr(getstor(d2x(x2d(ecvt)+ecvtocvt),4,1))
   kasid=x2d(getstor(d2x(x2d(ocvt)+x2d('18')),2,1))
   fds=getstor(d2x(x2d(ocvt)+x2d('58')),4,1)
   alet.fds='SYSZBPX2'
   kds=getstor(d2x(x2d(ocvt)+x2d('48')),4,1)
   alet.kds='SYSZBPX1'
   asvt=getstor(d2x(x2d(cvt)+556),4,kasid)
   ascb=getstor(d2x(x2d(asvt)+528+kasid*4-4),4,kasid)
   assb=getstor(d2x(x2d(ascb)+x2d('150')),4,kasid)
   stok=getstor(d2x(x2d(assb)+48),8,kasid)
   ocve=getstor(d2x(x2d(ocvt)+ocvtocve),4,kasid)
   return

/**********************************************************************/
getsysnames:
   sysnames.=''
   nxab=getstor(d2x(x2d(ocve)+x2d('84')),4,kasid)
   if nxab=0 then return
   nxmb=getstor(d2x(x2d(nxab)+x2d('14')),4,kasid)
   nxar=getstor(d2x(x2d(nxmb)+x2d('30')),4,kasid)
   sysid=x2d(getstor(d2x(x2d(nxmb)+x2d('c')),1,kasid))
   nxarl=32*x2d(getstor(d2x(x2d(nxmb)+x2d('18')),4,kasid))
   nxarray=getstor(nxar,nxarl,kasid)
   sysnames.=''
   do i=0 by 32 to nxarl-1
      nxent=extr(nxarray,d2x(i),32)
      entid=x2d(extr(nxent,0,1))
      if entid=0 then iterate
      entname=x2c(extr(nxent,8,8))
      sysnames.entid=entname
   end
   return

/**********************************************************************/
getstor: procedure expose ipcs pfs  alet. kasid
   arg $adr,$len,$asid,$alet
   if $asid='' then
      $asid=kasid
   $dspname=alet.$alet
   $c1=x2d(substr($adr,1,1))
   if length($adr)>7 & $c1>7 then
      do
      $c1=$c1-8
      $adr=$c1 || substr($adr,2)
      end
   if $asid='' then
      do
      say 'missing asid'
      i=1/0 /* get traceback */
      end
   opts='asid('$asid')'
   if $dspname<>'' then
      opts=opts 'DSPNAME('$dspname')'
   call $fetch$ $adr,$len,$alet,opts
   return cbx

/**********************************************************************/
getstor64: procedure expose ipcs pfs  alet. kasid
   arg $adr,$len,$asid
   if $asid='' then
      $asid=kasid
   $adr=right($adr,16,0)
   if $asid='' then
      do
      say 'missing asid'
      i=1/0 /* get traceback */
      end
   opts='asid('$asid')'
   call $fetch$ $adr,$len,0,opts
   return cbx

/**********************************************************************/
$fetch$:
   arg addr,cblen,alet,opts
   addr=fixaddr(addr)
   cbx=''
   if ipcs then
      do while cblen>0
         if cblen>512 then
            i=512
          else
            i=cblen
         address ipcs 'EVALUATE' addr'. LENGTH('i') REXX(STORAGE(CBS))',
               translate(opts)
         if rc<>0 then
            do
            call say 'Storage not available, addr:' addr ' len:' i
            return 1
            end
         cbx=cbx||cbs
         drop cbs
         cblen=cblen-i
         addr=d2x(x2d(addr)+i)
      end
    else
    if length(addr)<16 then
      do
      len=d2c(right(cblen,8,0),4)
      addrc=d2c(x2d(addr),4)
      aletc=d2c(x2d(alet),4)
      cbs=aletc || addrc || len
      address syscall 'pfsctl KERNEL -2147483647 cbs' max(cblen,12)
      if retval=-1 then
         do
         call say 'Error' errno errnojr 'getting storage at' arg(1),
                  'for length' cblen
         exit
         end
      cbx=c2x(substr(cbs,1,cblen))
      end
    else
      do
      len=d2c(right(cblen,8,0),4)
      addrc=d2c(x2d(addr),8)
      cbs=addrc || len
      address syscall 'pfsctl KERNEL -2147483646 cbs' max(cblen,12)
      if retval=-1 then
         do
         call say 'Error' errno errnojr 'getting storage64 at' arg(1),
                  'for length' cblen
         exit
         end
      cbx=c2x(substr(cbs,1,cblen))
      end
   return 0

/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)

/**********************************************************************/
fixaddr: procedure
   if length(arg(1))>8 then return arg(1)
   fa=right(arg(1),8,0)
   fa1=x2d(substr(fa,1,1))
   if fa1>7 then
      do
      fa1=fa1-8
      fa=fa1 || substr(fa,2)
      end
   return fa

/**********************************************************************/
say:
   trace o
   pl=translate(arg(1),,"'"xrange('00'x,'3f'x))
   if ipcs then
      address ipcs "NOTE '"pl"' ASIS"
    else
      say pl
   return

/**********************************************************************/
gettod:
   numeric digits 20
   tz=x2d(getstor(d2x(x2d(cvt)+x2d(130)),4),4)
   tz=format(tz*1.04852,,0)*4096000000
   if ipcs then
      do
      address ipcs "EVALUATE 48. LENGTH(8) REXX(STORAGE(LOCTOD)) HEADER"
      gmt=d2x(x2d(loctod)-tz)
      end
    else
      do
      address syscall 'time'
      gmt=e2tod(retval)
      end
   return gmt

/**********************************************************************/
tod2e:
   numeric digits 22
   arg htod
   tod1970=9048018124800000000
   todsec=4096000000
   pt=x2d(htod'00000000')-tod1970
   if pt<0 then return 0
   return format(pt/todsec,,0)

/**********************************************************************/
toddiff:
   numeric digits 22
   parse arg new,old
   diff=x2d(new)-x2d(old)
   return format((diff%4096000)/1000,,3)

/**********************************************************************/
e2tod: procedure
   arg etime
   numeric digits 20
   i=etime*2*x2d('7A120000')
   i=i+x2d('7D91048BCA000000')
   tod=d2x(i)
   return tod

/**********************************************************************/
xadd: procedure
   return d2x(x2d(arg(1))+x2d(arg(2)))

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose ipcs
   parse arg dumpbuf
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "*"ln"*"
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then call say '...'
         sk=0
         prev=out
         call say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return

