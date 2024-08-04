---
title: 'Wiki: Storm.dll Functions'
author: ron
layout: wiki
permalink: "/wiki/Storm.dll_Functions"
date: '2024-08-04T15:51:38-04:00'
---

This is a list of all Storm.dll functions that I\'ve found. Where possible, I\'ve tried to give them their official name (which can be gleaned from the Macintosh Storm.dll file). The vast majority of these were found by me, but I did find a couple on websites, most notably the non-class SFile functions.

If you have more, please feel free to post them. If you want to clean up my list, feel free. If you want to figure out what the parameters mean, be my guess. If you want to fill in the calling convention/parameters for functions that don\'t have any (or put ( void ) if there aren\'t any parameters), I\'d appreciate it.

I may add to this list in the future as I track down more.

## The List {#the_list}

    **note - these are all __stdcall unless otherwise noted

    102    SNetDestroy()
    117    SNetInitializePRovider()
    119    SNetLeaveGame()
    120    SNetPerformUpgrade(int)
    122    SNetReceiveTurns(void **,int,int,int,int);
    123    SNetRegisterEventHandler()

    132    int __fastcall  0CDebugSCritSect(LPCRITICAL_SECTION lpCriticalSection)
    141        __thiscall  CDebugSRWLock::CDebugSRWLock(void)
    142        __thiscall  CSRWLock::CSRWLock(void)
    143        __thiscall  SCritSect::SCritSect(void)
    144        __thiscall  SEvent::SEvent(BOOL bManualReset,BOOL bInitialState)
    145        __thiscall  SSyncObject::SSyncObject(void)
    146        __thiscall  CDebugSCritSect::~CDebugSCritSect(void)
    147        __thiscall  CDebugSRWLock::~CDebugSRWLock(void)
    148        __thiscall  CSRWLock::~CSRWLock(void)
    149        __thiscall  SCritSect::~SCritSect(void)
    152        __thiscall  SSyncObject::~SSyncObject(void)
    153                    SFile::Close(SFile *)
    154    int __fastcall  SThread::Create(unsigned int (__stdcall *)(void *),void *,class SThread &,char *)
    155                    SFile::CreateOverlapped(SOVERLAPPED *)
    156                    SFile::DestroyOverlapped(OVERLAPPED *)
    157                    SFile::EnableHash(bool)
    158    void __thiscall CDebugSCritSect::Enter(char const *,unsigned long)
    159    void __thiscall CDebugSRWLock::Enter(int,char const *,unsigned long)
    160    void __thiscall CSRWLock::Enter(int)
    161    int             SCritSect::enter(void)
    162                    SFile::FileExists(char const *)
    163                    SFile::GetActualFileName(SFile *,char *,unsigned long)
    164                    SFile::GetBasePath(char *,unsigned long)
    165                    SFile::GetFileSize(SFile *,unsigned long)
    166    void __thiscall CDebugSCritSect::Leave(char const *,unsigned long)
    167    void __thiscall CDebugSRWLock::Leave(int,char const *,unsigned long)
    168    void __thiscall CSRWLock::Leave(int)
    169��int             SCritSect::leave(void)
    170                    SFile::Load(SArchive *,char const *,void **,unsigned long *,unsigned long,unsigned long,SOVERLAPPED *)
    171                    SFile::LoadFile(char const *,void **,unsigned long *,unsigned long, SOVERLAPPED *)
    172                    SFile::Open(char const *,SFile **)
    173                    SFile::PollOverlapped(SOVERLAPPED *)
    174                    SFile::Read(class SFile *,void *,unsigned long,unsigned long *,struct SOVERLAPPED *,struct _TASYNCPARAMBLOCK *)
    175    int __thiscall  SEvent::Reset(void)
    176                    SFile::ResetOverlapped(SOVERLAPPED *)
    177    int __fastcall  SCreateThread(unsigned int (__stdcall *)(void*),void*,unsigned int*,void*,char*);
    188    int __thiscall  SEvent::Set(void)
    189                    SFile::SetBasePath(char const *)
    190                    SFile::SetFilePointer(SFile *,long,long*,unsigned long)
    191                    SFile::Unload(void *)
    193    int __stdcall          WaitMultiplePtr(BOOL bWaitAll,DWORD dwMilliseconds)
    194                    SFile::WaitOverlapped(struct SOVERLAPPED *)192    int __stdcall Wait(DWORD dwMilliseconds)

    251    SFileAuthenticateArchive(HANDLE hArchive,BOOL *isGood)
    252    SFileCloseArchive(HANDLE hArchive)
    253    SFileCloseFile(HANDLE hFile)
    262    SFileDestroy()
    264    SFileGetFileArchive(HANDLE hFile,int)
    265    SFileGetFileSize(HANDLE hFile, int *fileSizeHigh)
    266    SFileOpenArchive(char *name, int flags, int, HANDLE *hArchive)
    267    SFileOpenFile(int,int)
    268    SFileOpenFileEx(HANDLE hArchive, char *fileName, int, HANDLE *hFile)
    269    SFileReadFile(HANDLE hFile, void *buffer, int toRead, int *read, int)
    270    SFileSetBasePath(int)
    271    SFileSetFilePointer(HANDLE hFile, int filePos, int *filePosHigh, int method)
    272    SFileSetLocale(__int16)
    273    SFileGetBasePath(int,int)
    275    SFileGetArchiveName(int,int,int)
    276    SFileGetFileName(int,int,int)
    299    SFileAuthenticateArchiveEx(int,int,int,LONG lDistanceToMove,int,DWORD NumberOfBytesRead)

    301    StormDestroy

    321    SBmpDecodeImage
    323    SBmpLoadImage(int,int,int,int,int,int,int)
    324    SBmpSaveImageSBmpSaveImage(int,int,int,int,int,int)
    325    SBmpAllocLoadImage(char *filename,int,int,int,int,int,int,int)
    326    SBmpSaveImageEx(char *str,int,int,int,DWORD NumberOfBytesWritten,int,LPCVOID lpBuffer)

    331    SCodeCompile(char *src,int,int,int,int,int)
    332    SCodeDelete()
    335    SCodeGetPseudocode(int,int,int)

    341     SDrawVidDriverInitialize()
    342     SDrawCaptureScreen(char *path);
    343     SDrawShowCursor (?)
    344     SDrawDestroy()

    372     SEvtDispatch()
    373     SEvtRegisterHandler()
    375     SEvtUnregisterType

    382     SGdi1
    383     SGdi2
    392     SGdi4

    401 void *__stdcall SMemAlloc(int amount,char *filename,int line,int defaultValue)
    403                 SMemFree(int,int,int,int)
    404                 SMemGetSize()
    405                 SMemReAlloc(int,int,int,int,int);

    421 int SRegLoadData(HKEY hKey,LPCSTR lpValueName,HKEY phkResult,LPBYTE lpData,int,DWORD Type);
    423 int SRegQueryValue(char *key,char *value,BYTE flags,char *result)

    434     STrans1
    436     STrans2
    437     STrans4
    438     STrans3
    439     STransLoadI(int,int,int,int);
    440     STrans7
    443     STrans5
    447     STransLoadE(int,int,int,int);

    451     SVidDestroy
    453     SVidInitialize
    454     SVidPlayBegin
    455     SVidPlayBeginFromMemory
    456     SVidPlayContinue
    457     SVidPlayContinueSingle

    461     SErrDisplayError(int,int,DWORD ExitCode,int,int,UINT uExitCode)
    462     SErrGetErrorStr
    463     SErrGetLastError
    465     SErrSetLastError(DWORD dwErrCode)

    475     ? - ProcessToken

    481     SMemFindNextBlock()
    482     SMemFindNextHeap()
    483     SMemGetHeapByCaller()
    484     SMemGetHeapByPtr()
    485     SMemHeapAlloc()
    486     SMemHeapCreate()
    487     SMemHeapDestroy()
    488     SMemHeapFree()
    489     SMemHeapRealloc()
    490     SMemHeapSize()
    491 int SMemCpy(void *dest, void *src, int count)
    492 void __stdcall SMemSet(int destination,int length,char character);
    494 int SMemZero(void *buf, int count)
    495 int __stdcall SMemCmp(int str1,int str2,int length);
    497     SMemDumpState()

    501 int SStrNCpy(char *dst, char *src, int count)
    502 DWORD SStrHash(LPCSTR String, BOOLEAN IsFilename, DWORD Seed) 
    503 int SStrNCat(char *base, char *new, int max_length);
    506 SStrLen(str, max);

    508 int SStrCmp(char *str1,char *str2,size_t size);
    509 int SStrCmpI(char *str1,char *str2,size_t size);
    510 int SStrUpr(char *str)
    Note - 569,571 and 570,572 are the same functions
    569 char *__fastcall SStrChr(char *str,char c); // Returns the substring after the first occurance of the specific character in the string.  Returns NULL if the character is not found.
    570 char *__fastcall SStrChrR(const char *str,char c); // Returns the address of the final occurance of c within the string str.  If it is not found, NULL is returned.
    571 char *__stdcall SStrChr(char *str,char c); // Returns the substring after the first occurance of the specific character in the string.  Returns NULL if the character is not found.
    572 char *__fastcall SStrChrR(const char *str,char c); // Returns the address of the final occurance of c within the string str.  If it is not found, NULL is returned.
    578 SStrPrintf(char *str, size_t size, const char *format, ...);
    579 SStrLwr(char *str)

    548     Add to log file (not sure about official name)

    601 SBigAdd(int,int,int)
    602 SBigAnd(int,int,int)
    603 SBigCompare(BigBuffer buf1,BigBuffer buf2)
    604 SBigCopy(int,int)
    605 SBigDec(int,int)
    606 SBigDel(BigBuffer buf)
    607 SBigDiv(int,int,int)
    608 SBigFindPrime(int,int,int,int)
    609 SBigFromBinary(BigBuffer *,const void *str,unsigned int size_in_bytes)
    610 SBigFromStr(int,int)
    611 SBigFromStream(int,int,int,int)
    612 SBigFromUnsigned(BigBuffer buf,unsigned int value)
    613 SBigGcd(int,int,int)
    614 SBigInc(int,int)
    615 SBigInvMod(int,int,int)
    616 SBigIsEven(BigBuffer buf)
    617 SBigIsOdd(BigBuffer buf)
    618 SBigIsOne(BigBuffer buf)
    619 SBigIsPrime(BigBuffer buf)
    620 SBigIsZero(BigBuffer buf)
    621 SBigMod(int,int,int)
    622 SBigMul(int,int,int)
    623 SBigMulMod(int,int,int,int)
    624 SBigNew(BigBuffer **Buffer) 
    625 SBigNot(int,int)
    626 SBigOr(int,int,int)
    627 SBigPow(int,int,int)
    628 int __stdcall SBigPowMod(BigBuffer *output,BigBuffer *base,BigBuffer *power,BigBuffer *mod);
    629 SBigRand(int,int,int)
    630 SBigSet2Exp(int,int)
    631 SBigSetOne(BigBuffer *buf)
    632 SBigSetZero(BigBuffer *buf)
    633 SBigShl(int,int,int)
    634 SBigShr(int,int,int)
    635 SBigSquare(int,int)
    636 SBigSub(int,int,int)
    637 SBigToBinaryArray(int,int,int)
    638 int __stdcall SBigToBinaryBuffer(BigBuffer *buffer,char *str_buffer,int size,int);
    639 SBigToBinaryPtr(int,int,int)
    640 SBigToStrArray(int,int)
    641 SBigToStrBuffer(int,char *dst,int count)
    642 SBigToStrPtr(int,int)
    643 SBigToStreamArray(int,int,int)
    644 SBigToStreamBuffer(int,int,int,int)
    645 SBigToStreamPtr(int,int,int)
    646 SBigToUnsigned(int,int)
    647 SBigXor(int,int,int)


    649 SSignatureVerifyStream_Begin(int)
    648 SSignatureVerify(int,int,int,int)
    650 SSignatureVerifyStream_ProvideData(int)
    651 SSignatureVerifyStream_Finish(int)
    652 SSignatureGenerate(int,int,int,int,int,int)
    653 SSignatureVerifyStream_GetSignatureLength()
