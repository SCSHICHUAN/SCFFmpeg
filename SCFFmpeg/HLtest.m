//
//  HLtest.m
//  HLFFmpeg
//
//  Created by stan on 2024/3/11.
//

#import "HLtest.h"
#import "HLFFmpeg.h"
#import <libavformat/avformat.h>
#import <libswscale/swscale.h>



@implementation HLtest


HLtest *c_self = nil;

-(instancetype)init{
    self = [super init];
    if(self){
        [self initCon];
    }
    return self;
}

-(void)initCon{
    c_self = self;
}

static int decode_write_frame(const char *outfilename, AVCodecContext *avctx,
                              struct SwsContext *sws_convert_ctx, AVFrame *frame, int *frame_count, AVPacket *pkt, int last,AVStream *st,int start_time,int end_time)
{
    AVPicture *bmp;
    int len, got_frame;
    char buf[1024];
    
    /*
     开始解码
     avctx     : 编解码器环境
     frame     : 输出帧
     got_frame : 是否解码完成一帧
     pkt       : 输入数据
     */
    len = avcodec_decode_video2(avctx, frame, &got_frame, pkt);
    if (len < 0) {
        fprintf(stderr, "Error while decoding frame %d\n", *frame_count);
        return len;
    }
    //如果解码完成一帧
    if (got_frame) {
        //判断是否大于结束时间 ms
        float pkg_time = av_q2d(st->time_base) * pkt->pts * 1000;
        printf("av_pkg_time = %f ms\n",pkg_time);
        
        
        /*
         start_time < pkg_time
         修复100ms到100ms 取多帧bug
         */
        if (start_time <= pkg_time) {
            
            printf("Saving %sframe %3d\n", last ? "last " : "", *frame_count);
//            count = *frame_count;
            fflush(stdout);
            
            /* the picture is allocated by the decoder, no need to free it */
            snprintf(buf, sizeof(buf), "%s-%d.bmp", outfilename, *frame_count);
            
           
            dispatch_async(dispatch_get_main_queue(), ^{
//                [c_self->render displayWithFrame:frame];
            });
            (*frame_count)++;
        }
    }
    return 0;
}


-(int)run{
    
    
//        const char *a = "http://www.w3school.com.cn/i/movie.mp4";
    const char *a = "http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8";
//        const char *a = "http://vjs.zencdn.net/v/oceans.mp4";
//    const char *a = "rtmp://mobliestream.c3tv.com:554/live/goodtv.sdp";


    
    
    const char *b = "/Users/stan/Desktop/p/a";
    
    const  char *argv[] ={"",a,b,"0","10000"};
    
    
    int ret;
    
    FILE *f = NULL;
    
    const char *filename, *outfilename;
    int64_t  start_time,end_time;
    
    AVFormatContext *fmt_ctx = NULL;
    
    const AVCodec *codec;
    AVCodecContext *codec_ctx= NULL;
    
    AVStream *st = NULL;
    int stream_index;
    
    int frame_count;
    AVFrame *frame;
    
    struct SwsContext *sws_convert_ctx;
    
    //uint8_t inbuf[INBUF_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];
    AVPacket avpkt;
    
    
    filename    = argv[1];
    outfilename = argv[2];
    start_time  = atoi(argv[3]);
    end_time    = atoi(argv[4]);
    
    /* register all formats and codecs */
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    
    /*打开输入文件
     open input file, and allocate format context */
    if (avformat_open_input(&fmt_ctx, filename, NULL, NULL) < 0) {
        fprintf(stderr, "Could not open source file %s\n", filename);
        exit(1);
    }
    
    /*找到输入文件的信息
     retrieve stream information */
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        fprintf(stderr, "Could not find stream information\n");
        exit(1);
    }
    
    /*打印输入文件的信息
     dump input information to stderr */
    av_dump_format(fmt_ctx, 0, filename, 0);
    
    
    //找到视频流
    ret = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO), filename);
        return ret;
    }
    
    stream_index = ret;
    //拿到视频流的实例
    st = fmt_ctx->streams[stream_index];
    
    /*
     找到视频流的编解码器
     find decoder for the stream */
    codec = avcodec_find_decoder(st->codecpar->codec_id);
    if (!codec) {
        fprintf(stderr, "Failed to find %s codec\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return AVERROR(EINVAL);
    }
    
    //分配编解码器上下文
    codec_ctx = avcodec_alloc_context3(NULL);
    if (!codec_ctx) {
        fprintf(stderr, "Could not allocate video codec context\n");
        exit(1);
    }
    
    /*编解码器拷贝到创建的上下文中
     Copy codec parameters from input stream to output codec context */
    if ((ret = avcodec_parameters_to_context(codec_ctx, st->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return ret;
    }
    
    
    /*打开编解码器环境
     open it */
    if (avcodec_open2(codec_ctx, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }
    
    //图片视频裁剪 初始化
    sws_convert_ctx = sws_getContext(codec_ctx->width, codec_ctx->height,
                                     codec_ctx->pix_fmt,
                                     codec_ctx->width, codec_ctx->height,
                                     AV_PIX_FMT_BGR24,
                                     SWS_BICUBIC, NULL, NULL, NULL);
    
    if (sws_convert_ctx == NULL)
    {
        fprintf(stderr, "Cannot initialize the conversion context\n");
        exit(1);
    }
    
    //初始化frame
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }
    
    //初始化AVPacket
    av_init_packet(&avpkt);
    
    
    //读取输入上下文的数据
    frame_count = 1;
    
    
    //    while (av_read_frame(fmt_ctx, &avpkt) >= 0) {
    //        if (wellDone) {
    //            break;
    //        }
    //        //如果是视频流
    //        if(avpkt.stream_index == stream_index){
    //            if (decode_write_frame(outfilename, codec_ctx, sws_convert_ctx, frame, &frame_count, &avpkt, 0,st,start_time,end_time) < 0)
    //                exit(1);
    //        }
    //        av_packet_unref(&avpkt);
    //    }
    
    //    avpkt.data = NULL;
    //    avpkt.size = 0;
    fclose(f);
    //    avformat_close_input(&fmt_ctx);
    //    sws_freeContext(sws_convert_ctx);
    //    avcodec_free_context(&codec_ctx);
    //    av_frame_free(&frame);
    //    printf("start_time = %lld,end_time = %lld\n",start_time,end_time);
    
    [c_self redFream:fmt_ctx pkt:avpkt videoIndex:stream_index outfilename:outfilename codec_ctx:codec_ctx sws_convert_ctx:sws_convert_ctx frame:frame frame_count:frame_count st:st start_time:start_time end_time:end_time];
    
    return 0;
}


-(void)redFream:(AVFormatContext *)fmt_ctx
            pkt:(AVPacket )avpkt
     videoIndex:(int)stream_index
    outfilename:(const char*)outfilename
      codec_ctx:(AVCodecContext *)codec_ctx
sws_convert_ctx:(struct SwsContext *)sws_convert_ctx
          frame:(AVFrame *)frame
    frame_count:(int *)frame_count
             st:(AVStream *)st
     start_time:(int64_t)start_time
       end_time:(int64_t)end_time{
    
    if (av_read_frame(fmt_ctx, &avpkt) >= 0) {
        
        //如果是视频流
        if(avpkt.stream_index == stream_index){
            if (decode_write_frame(outfilename, codec_ctx, sws_convert_ctx, frame, &frame_count, &avpkt, 0,st,start_time,end_time) < 0)
                exit(1);
        }
        av_packet_unref(&avpkt);
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1/60.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [c_self redFream:fmt_ctx pkt:avpkt videoIndex:stream_index outfilename:outfilename codec_ctx:codec_ctx sws_convert_ctx:sws_convert_ctx frame:frame frame_count:frame_count st:st start_time:start_time end_time:end_time];
    });
    
    
    //    avpkt.data = NULL;
    //    avpkt.size = 0;
    ////    fclose(f);
    //    avformat_close_input(&fmt_ctx);
    //    sws_freeContext(sws_convert_ctx);
    //    avcodec_free_context(&codec_ctx);
    //    av_frame_free(&frame);
    //    printf("start_time = %lld,end_time = %lld\n",start_time,end_time);
}



@end
