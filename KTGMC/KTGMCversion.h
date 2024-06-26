#pragma once
#ifndef __KTGMC_VERSION_H__
#define __KTGMC_VERSION_H__

#include "KVersion.h"

#define DLL_VERSION      VER_FILEVERSION
#define DLL_VERSION_STR  VER_STR_FILEVERSION
#define DLL_NAME         "KTGMC.dll"
#define DLL_FULL_NAME    "KTGMC"
#define DLL_VERSION_NAME "KTGMC " VER_STR_FILEVERSION
#define DLL_VERSION_INFO AUF_VERSION_NAME

#ifdef DEBUG
#define VER_DEBUG   VS_FF_DEBUG
#define VER_PRIVATE VS_FF_PRIVATEBUILD
#else
#define VER_DEBUG   0
#define VER_PRIVATE 0
#endif

#define VER_STR_COMMENTS         DLL_FULL_NAME
#define VER_STR_COMPANYNAME      ""
#define VER_STR_FILEDESCRIPTION  DLL_FULL_NAME
#define VER_STR_INTERNALNAME     DLL_FULL_NAME
#define VER_STR_ORIGINALFILENAME DLL_NAME
#define VER_STR_LEGALCOPYRIGHT   DLL_FULL_NAME
#define VER_STR_PRODUCTNAME      "KTGMC"
#define VER_PRODUCTVERSION       VER_FILEVERSION
#define VER_STR_PRODUCTVERSION   VER_STR_FILEVERSION

#endif //__KTGMC_VERSION_H__
