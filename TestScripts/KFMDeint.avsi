# KFM��KTGMC���g�����C���^���[�X����
# requires AvisynthNeo

function KFMDeint(clip src, int "mode", string "preset", float "thswitch", bool "ucf", bool "nr", bool "gentime", bool "cuda", int "dev", bool "show") {

    mode = default(mode, 0) # 0:VFR(60fps) 1:60fps 2:24fps
    preset = default(preset, "Faster") # QTGMC preset
    thswitch = default(thswitch, 0.5)
    ucf = default(ucf, false) # Enable DecombUCF
    nr = default(nr, false) # Enable Noise Reduction with (K)SMDegrain
    gentime = default(gentime, false) # generate VFR timecode (returns timecode clip)
    cuda = default(cuda, false) # Enable CUDA
    dev = default(dev, 0) # CUDA device index
    show = default(show, false) # Show information
    
    ivtc = Select(mode, true, false, true) # Enable Inverse Telecine
    out24 = Select(mode, false, false, true) # output 24fps

	# CUDA�f�o�C�X�`�F�b�N
	if(cuda) {
		cc = CUDAComputeCapability(dev)
		Assert(cc >= 35, "[KFM CUDA Error] Specified GPU: " + CUDADeviceName(dev) + " is not usable. (CC=" + string(cc) + " < 35)")
	}
    
    OnDEV = cuda ? function[dev](clip c) { c.OnCUDA(2, dev) } : function(clip c) { c }

    # KFMPad�͏㉺��4�s�N�Z���i���v8�s�N�Z���j�g������
    pad = src.KFMPad()

    ## 60fps�N���b�v����� ##

    # QTGMC/KTGMC���Ăяo�� useFlag�� 0:�ʏ� 1:�O�̃t�B�[���h�������g���ĕ�� 2:���̃t�B�[���h�������g���ĕ��
    # useFlag��KTGMC�̂ݑΉ��iQTGMC�͖��������j
    # �����x�N�g���Ȃǂ͍ė��p����̂�0���ŏ��ɌĂяo���Ă���1,2���Ăяo������
    xTGMC = function[preset, cuda, dev](clip c, int useFlag) {
        prevGlobals = (useFlag == 0) ? "Replace" : "Reuse"
        cuda ? c.KTGMC(Preset=preset, dev=dev, PrevGlobals=prevGlobals, useFlag=useFlag) : c.QTGMC(Preset=preset).Prefetch(4)
    }

    # 16 == (Blocksize - Overlap): �u���b�N�T�C�Y�ɍ��킹��
    call_xTGMC = function[preset, src, pad, xTGMC](int useFlag) {
        is_pad = (preset == "Faster" && (Height(src) % 16) == 8)
        srcq = is_pad ? pad : src
        p60 = srcq.xTGMC(useFlag)
        is_pad ? p60.Crop(0,4,0,-4) : p60
    }
    
    # �Î~������ԗp
    stt = src.KAnalyzeStatic(30, 15, pad)

    clip60 = call_xTGMC(0).KMergeStatic(src, stt)
    
    if(ucf) {
        # �m�C�Y���N���b�v�쐬�֐�
        UCFNoise = function[pad, cuda, OnDev](clip src) {
            if(cuda) {
                # �m�C�Y����̏����B�O��4�s�N�Z���͔��肩�珜�O�BCrop���CUDA�ŏ�������̂�Align�K�{
                fields = src.SeparateFields().Crop(4,4,-4,-4).Align()
                # �I���W�i����DecombUCF����Crop�O��binomialBlur���|���Ă������ACrop��Align�������Ȃ�̂�
                # Crop��Ɋ|�����Ⴄ�B�������ʂ��ς�邩������Ȃ����ǂ��܂�ς��Ȃ��Ǝv��
                # �I���W�i����binomialBlur�͗��_�I�ɂ�p=2.5�����i��������ׂ�ƃt�B���^�͈͂̈Ⴂ��鍷�͌��\�o�Ă�j
                noise = fields.KGaussResize(p=2.5)
                # �m�C�Y����̂��߂̏����W�v�BKAnalyzeNoise�̌��ʂ�CPU����A�N�Z�X�����̂�OnCUDA���Ă���
                src.KAnalyzeNoise(fields.KNoiseClip(noise), pad).OnDEV()
            }
            else {
                fields = src.SeparateFields().Crop(4,4,-4,-4)
                w = fields.Width()
                h = fields.Height()
                epsilon = 0.0001
                noise = fields.GaussResize( w,h, 0,0, w+epsilon,h+epsilon, p=2.5 )
                src.KAnalyzeNoise(fields.KNoiseClip(noise), pad)
            }
        }

        # DecombUCF�p�����[�^
        ucfparam = KDecombUCFParam()
        # �m�C�Y���N���b�v
        noise30 = src.UCFNoise()
        
        if(cuda) {
            before60 = call_xTGMC(1).KMergeStatic(src, stt)
            after60 = call_xTGMC(2).KMergeStatic(src, stt)
        }
        else {
            # CPU�ł͑Ή����Ă��Ȃ��̂�TDeint���g��
            before60 = src.TDeint(chroma=true,mode=1,edeint=src.nnedi3(field=-2),emask=src.TMM2(mode=1, order=-1, field=-1))
            after60 = before60
        }
        
        if(show) {
            before60 = before60.Print("*** BOB BEFORE ***", y=20)
            after60 = after60.Print("*** BOB AFTER ***", y=20)
        }
    }
    
    if(ivtc) {

        if(show) {
            clip60 = clip60.Print("****** BOB ******", y=20)
        }

        ## �t�e���V�l��� ##

        # KFM��͗p�N���b�v
        super = src.KFMSuper(pad)

        # 30fps��KFM��͗p�N���b�v
        super30 = super.SelectEven()

        # �e���V�l��͔��� KFMCycleAnalyze��CUDA��Ή��Ȃ̂Œ���
        fmclip = super.KPreCycleAnalyze().OnDEV().KFMCycleAnalyze(src).OnCPU(0)

        # �t�e���V�l����KFM��͗p�N���b�v
        super24 = super.KTelecineSuper(fmclip)

        # �t�e���V�l �ȏ����̓m�C�Y�ጸ�̂���
        #clip24 = src.KTelecine(fmclip).KFMPad().KRemoveCombe(super24)
        clip24 = pad.KTelecine(fmclip).KRemoveCombe(super24)

        if(ucf) {
            # DoubleWeave�����N���b�v �ȏ����̓m�C�Y�ጸ�̂���
            #dweave = src.DoubleWeave().KFMPad().KRemoveCombe(super)
            dweave = pad.DoubleWeave().KRemoveCombe(super)

            if(show) {
                dweave = dweave.Print("** DOUBLE WEAVE **", y=20)
            }

            # DecombUCF��K�p(24fps)
            clip24 = clip24.KDecombUCF24(ucfparam, fmclip, noise30, before60, after60, dweave)
        }

        if(nr) {
            if(cuda) {
                if(out24) {
                    # 24fps�o�͂̎��͍��������邽�ߌy�߂̐ݒ�ɂ���
                    clip24 = clip24.KSMDegrain(tr=1, chroma=False, binomial=True, dev=dev)
                }
                else {
                    clip24 = clip24.KSMDegrain(binomial=True, dev=dev)
                }
            }
            else {
                clip24 = clip24.SMDegrain(tr=1)
            }
        }

        # 24fps/60fps �؂�ւ��}�X�N�imask��cc���Z�b�g�Ŏg���j
        flag24 = super24.KSwitchFlag()
        mask24 = clip24.KCombeMask(flag24)
        cc24 = flag24.KContainsCombe().OnDEV() # CPU����A�N�Z�X�����̂�OnCUDA���Ă���

        if(out24) {
            clip24.KPatchCombe(clip60, fmclip, mask24, cc24)
        }
        else {
            clip30 = show ? src.Print("****** SOURCE *****", y=20) : src
            if(ucf) {
                # DecombUCF��K�p(30fps)
                clip30 = clip30.KDecombUCF(ucfparam, noise30, before60, after60)
            }
            if(nr) {
                # 30fps�͌y�߂̐ݒ�ōs��
                if(cuda) {
                    clip30 = clip30.KSMDegrain(tr=1, chroma=False, binomial=True, dev=dev)
                }
                else {
                    clip30 = clip30.SMDegrain(tr=1)
                }
            }

            # 30fps/60fps �؂�ւ��}�X�N�imask��cc���Z�b�g�Ŏg���j
            flag30 = super30.KSwitchFlag()
            mask30 = clip30.KCombeMask(flag30)
            cc30 = flag30.KContainsCombe().OnDEV() # CPU����A�N�Z�X�����̂�OnCUDA���Ă���

            # DecombUCF��K�p(60fps)
            ucfc = ucf ? clip60.KDecombUCF60(ucfparam, noise30, before60, after60) : Undefined()

            result = clip60.KFMSwitch(fmclip, clip24, mask24, cc24, clip30, mask30, cc30, ucfc, thswitch=thswitch, show=show, gentime=gentime)

            #(show && gentime) ? clip60.AMTVFRShow(result) : result
            result
        }
    }
    else {
        ucf ? clip60.KDecombUCF60(ucfparam, noise30, before60, after60) : clip60
    }
    
    if(cuda) {
		if(!gentime) {
			OnDEV()
		}
	}
	else {
		Prefetch(4)
	}
}