From d41ccc6a64b305cfc357e8d235eba0bd46e30c88 Mon Sep 17 00:00:00 2001
From: Jamie Coldhill <wrxtasy@amnet.net.au>
Date: Wed, 1 Feb 2017 20:22:47 +0800
Subject: [PATCH] 3D Automatic HDMI switch - rebase for Krypton

---
 .../cores/VideoPlayer/DVDCodecs/Video/AMLCodec.cpp |   9 +-
 xbmc/rendering/gles/RenderSystemGLES.cpp           |  18 ++--
 xbmc/rendering/gles/RenderSystemGLES.h             |   1 +
 xbmc/utils/AMLUtils.cpp                            | 115 ++++++++++++++++++++-
 xbmc/utils/AMLUtils.h                              |   2 +
 xbmc/utils/SystemInfo.cpp                          |  17 +++
 xbmc/utils/SystemInfo.h                            |   3 +
 7 files changed, 154 insertions(+), 11 deletions(-)

diff --git a/xbmc/cores/VideoPlayer/DVDCodecs/Video/AMLCodec.cpp b/xbmc/cores/VideoPlayer/DVDCodecs/Video/AMLCodec.cpp
index a5bc749..d2230c9 100644
--- a/xbmc/cores/VideoPlayer/DVDCodecs/Video/AMLCodec.cpp
+++ b/xbmc/cores/VideoPlayer/DVDCodecs/Video/AMLCodec.cpp
@@ -1745,6 +1745,7 @@ void CAMLCodec::CloseDecoder()
   // return tsync to default so external apps work
   SysfsUtils::SetInt("/sys/class/tsync/enable", 1);
 
+  SetVideo3dMode(MODE_3D_DISABLE);
   ShowMainVideo(false);
 
   CloseAmlVideo();
@@ -2113,8 +2114,14 @@ void CAMLCodec::SetVideoSaturation(const int saturation)
 
 void CAMLCodec::SetVideo3dMode(const int mode3d)
 {
+  static int old3dmode = MODE_3D_DISABLE;
+
+  if (mode3d == old3dmode)
+    return;
+
   CLog::Log(LOGDEBUG, "CAMLCodec::SetVideo3dMode:mode3d(0x%x)", mode3d);
   SysfsUtils::SetInt("/sys/class/ppmgr/ppmgr_3d_mode", mode3d);
+  old3dmode = mode3d;
 }
 
 std::string CAMLCodec::GetStereoMode()
@@ -2128,8 +2135,6 @@ std::string CAMLCodec::GetStereoMode()
     default:                                  stereo_mode = m_hints.stereo_mode; break;
   }
 
-  if(CMediaSettings::GetInstance().GetCurrentVideoSettings().m_StereoInvert)
-    stereo_mode = RenderManager::GetStereoModeInvert(stereo_mode);
   return stereo_mode;
 }
 
diff --git a/xbmc/rendering/gles/RenderSystemGLES.cpp b/xbmc/rendering/gles/RenderSystemGLES.cpp
index 4a592c7..b87bebd 100644
--- a/xbmc/rendering/gles/RenderSystemGLES.cpp
+++ b/xbmc/rendering/gles/RenderSystemGLES.cpp
@@ -652,17 +652,19 @@ GLint CRenderSystemGLES::GUIShaderGetBrightness()
   return -1;
 }
 
+void CRenderSystemGLES::SetStereoMode(RENDER_STEREO_MODE mode, RENDER_STEREO_VIEW view)
+{
+  CRenderSystemBase::SetStereoMode(mode, view);
+
+  g_sysinfo.HWSetStereoMode(mode, view);
+}
+
 bool CRenderSystemGLES::SupportsStereo(RENDER_STEREO_MODE mode) const
 {
-  switch(mode)
-  {
-    case RENDER_STEREO_MODE_INTERLACED:
-      if (g_sysinfo.HasHW3DInterlaced())
-        return true;
+  if (g_sysinfo.HWSupportsStereo(mode))
+    return true;
 
-    default:
-      return CRenderSystemBase::SupportsStereo(mode);
-  }
+  return CRenderSystemBase::SupportsStereo(mode);
 }
 
 GLint CRenderSystemGLES::GUIShaderGetModel()
diff --git a/xbmc/rendering/gles/RenderSystemGLES.h b/xbmc/rendering/gles/RenderSystemGLES.h
index f103cf5..03e1b12 100644
--- a/xbmc/rendering/gles/RenderSystemGLES.h
+++ b/xbmc/rendering/gles/RenderSystemGLES.h
@@ -78,6 +78,7 @@ public:
 
   void ApplyHardwareTransform(const TransformMatrix &matrix) override;
   void RestoreHardwareTransform() override;
+  void SetStereoMode(RENDER_STEREO_MODE mode, RENDER_STEREO_VIEW view) override;
   bool SupportsStereo(RENDER_STEREO_MODE mode) const override;
 
   bool TestRender() override;
diff --git a/xbmc/utils/AMLUtils.cpp b/xbmc/utils/AMLUtils.cpp
index cd19ec7..6bd1611 100644
--- a/xbmc/utils/AMLUtils.cpp
+++ b/xbmc/utils/AMLUtils.cpp
@@ -25,7 +25,9 @@
 #include <fcntl.h>
 #include <string>
 
-#include "AMLUtils.h"
+#include "rendering/RenderSystem.h"
+#include "settings/MediaSettings.h"
+#include "utils/AMLUtils.h"
 #include "utils/CPUInfo.h"
 #include "utils/log.h"
 #include "utils/SysfsUtils.h"
@@ -33,6 +35,43 @@
 #include "guilib/gui3d.h"
 #include "utils/RegExp.h"
 
+#define MODE_HDMI3D_LR          "3dlr"
+#define MODE_HDMI3D_TB          "3dtb"
+#define MODE_HDMI3D_OFF         "3doff"
+
+static void aml_hdmi_3D_mode(const std::string mode3d)
+{
+  static std::string oldhdmi3dmode = MODE_HDMI3D_OFF;
+  static bool reset_disp_mode = false;
+
+  if (mode3d == oldhdmi3dmode)
+    return;
+
+  aml_set_sysfs_str("/sys/class/amhdmitx/amhdmitx0/config", mode3d.c_str());
+  oldhdmi3dmode = mode3d;
+
+  if (strstr(mode3d.c_str(), MODE_HDMI3D_OFF))
+  {
+    if (reset_disp_mode)
+    {
+      // Some 3D HDTVs will not exit from 3D mode with 3doff
+      char disp_mode[256] = {};
+      if (aml_get_sysfs_str("/sys/class/display/mode", disp_mode, 255) != -1)
+      {
+        aml_set_sysfs_int("/sys/class/graphics/fb0/blank", 1);
+        // Setting the same mode does not reset HDMI on M8
+        aml_set_sysfs_str("/sys/class/amhdmitx/amhdmitx0/disp_mode", "720p");
+        aml_set_sysfs_str("/sys/class/amhdmitx/amhdmitx0/disp_mode", disp_mode);
+        aml_set_sysfs_int("/sys/class/graphics/fb0/blank", 0);
+      }
+
+      reset_disp_mode = false;
+    }
+  }
+  else
+    reset_disp_mode = true;
+}
+
 bool aml_present()
 {
   static int has_aml = -1;
@@ -63,6 +102,80 @@ bool aml_hw3d_present()
   return has_hw3d == 1;
 }
 
+bool aml_supports_stereo(const int mode)
+{
+  static int last_mode = -1;
+  static bool last_rtn = false;
+  if (last_mode == mode)
+    return last_rtn;
+
+  char disp_cap_3d[256] = {};
+  if (aml_get_sysfs_str("/sys/class/amhdmitx/amhdmitx0/disp_cap_3d", disp_cap_3d, 255) == -1)
+  {
+    last_rtn = false;
+    last_mode = -1;
+    return last_rtn;
+  }
+
+  if (mode == RENDER_STEREO_MODE_INTERLACED && strstr(disp_cap_3d,"FramePacking"))
+    last_rtn = true;
+  else if (mode == RENDER_STEREO_MODE_SPLIT_HORIZONTAL && strstr(disp_cap_3d,"TopBottom"))
+    last_rtn = true;
+  else if (mode == RENDER_STEREO_MODE_SPLIT_VERTICAL && strstr(disp_cap_3d,"SidebySide"))
+    last_rtn = true;
+
+  last_mode = mode;
+
+  return last_rtn;
+}
+
+void aml_set_stereo_mode(const int mode, const int view)
+{
+  static int last_mode = -1;
+  // do nothing if mode matches last time someone called us.
+  if (last_mode == mode)
+    return;
+
+  if (!aml_supports_stereo(mode))
+  {
+    last_mode = mode;
+    return;
+  }
+
+  switch(mode)
+  {
+    default:
+      aml_hdmi_3D_mode("3doff");
+      break;
+    case RENDER_STEREO_MODE_SPLIT_VERTICAL:
+      aml_hdmi_3D_mode("3dlr");
+      break;
+    case RENDER_STEREO_MODE_SPLIT_HORIZONTAL:
+      aml_hdmi_3D_mode("3dtb");
+      break;
+
+    case RENDER_STEREO_MODE_INTERLACED:
+      {
+        std::string  stereo_mode;
+        switch(CMediaSettings::GetInstance().GetCurrentVideoSettings().m_StereoMode)
+        {
+          case RENDER_STEREO_MODE_SPLIT_VERTICAL:
+            aml_hdmi_3D_mode("3dlr");
+            break;
+          case RENDER_STEREO_MODE_SPLIT_HORIZONTAL:
+            aml_hdmi_3D_mode("3dtb");
+            break;
+          default:
+            aml_hdmi_3D_mode("3doff");
+            break;
+        }
+      }
+      break;
+  }
+
+  return;
+}
+
 bool aml_wired_present()
 {
   static int has_wired = -1;
diff --git a/xbmc/utils/AMLUtils.h b/xbmc/utils/AMLUtils.h
index ba8b493..923f35d 100644
--- a/xbmc/utils/AMLUtils.h
+++ b/xbmc/utils/AMLUtils.h
@@ -52,6 +52,8 @@ enum AML_SUPPORT_H264_4K2K
 bool aml_present();
 bool aml_permissions();
 bool aml_hw3d_present();
+bool aml_supports_stereo(const int mode);
+void aml_set_stereo_mode(const int mode, const int view);
 bool aml_wired_present();
 bool aml_support_hevc();
 bool aml_support_hevc_4k2k();
diff --git a/xbmc/utils/SystemInfo.cpp b/xbmc/utils/SystemInfo.cpp
index fcc6733..0418e42 100644
--- a/xbmc/utils/SystemInfo.cpp
+++ b/xbmc/utils/SystemInfo.cpp
@@ -881,6 +881,23 @@ bool CSysInfo::HasHW3DInterlaced()
   return false;
 }
 
+bool CSysInfo::HWSupportsStereo(const int mode)
+{
+#if defined(HAS_LIBAMCODEC)
+  if (aml_present())
+    return aml_supports_stereo(mode);
+#endif
+  return false;
+}
+
+void CSysInfo::HWSetStereoMode(const int mode, const int view)
+{
+#if defined(HAS_LIBAMCODEC)
+  if (aml_present())
+    aml_set_stereo_mode(mode, view);
+#endif
+}
+
 CSysInfo::WindowsVersion CSysInfo::m_WinVer = WindowsVersionUnknown;
 
 bool CSysInfo::IsWindowsVersion(WindowsVersion ver)
diff --git a/xbmc/utils/SystemInfo.h b/xbmc/utils/SystemInfo.h
index 8f3e2f9..c4db454 100644
--- a/xbmc/utils/SystemInfo.h
+++ b/xbmc/utils/SystemInfo.h
@@ -118,6 +118,9 @@ public:
   bool HasVideoToolBoxDecoder();
   bool IsAeroDisabled();
   bool HasHW3DInterlaced();
+  bool HWSupportsStereo(const int mode);
+  void HWSetStereoMode(const int mode, const int view);
+
   static bool IsWindowsVersion(WindowsVersion ver);
   static bool IsWindowsVersionAtLeast(WindowsVersion ver);
   static WindowsVersion GetWindowsVersion();
-- 
2.7.4

