//
//  YoutubeViewController.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/5.
//  Copyright © 2019 leke. All rights reserved.
//

#import "YoutubeViewController.h"
#import "YoutubeFormatCell.h"
#import "WKUrlToModelTransform.h"
#import "WKDownLoadManager.h"
#import "ToastView.h"

@interface YoutubeViewController ()
<UITableViewDelegate,
UITableViewDataSource,
YoutubeFormatCellDelegate>

@property (weak, nonatomic) IBOutlet UITextField *urlTF;
@property (weak, nonatomic) IBOutlet UIButton    *downloadButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray<WKDownLoadTask *> *tasks;

@end

@implementation YoutubeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    _tableView.rowHeight = 50;
    [_tableView registerClass:[YoutubeFormatCell class] forCellReuseIdentifier:@"cell"];
    _tableView.separatorColor = [UIColor whiteColor];
    [_downloadButton addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSString *string = [UIPasteboard generalPasteboard].string;
    if (string && [string hasPrefix:@"https://you"] && ![string isEqualToString:_urlTF.text]) {
        _urlTF.text = string;
    } else {
        _urlTF.text = @"";
    }
}

#pragma mark - request
- (void)download {
    [_urlTF resignFirstResponder];
    [ToastView showLoading];
    [WKUrlToModelTransform transformYoutubeUrl:_urlTF.text complete:^(NSArray<WKDownLoadTask *> * _Nullable list, NSString * _Nullable error) {
        if (error) {
            [ToastView showMessage:error];
        } else {
            [ToastView hiddenLoading];
            self.tasks = list;
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - UITableViewDataSource UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YoutubeFormatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [cell configTask:self.tasks[indexPath.row]];
    cell.delegate = self;
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_urlTF resignFirstResponder];
}

#pragma mark - YoutubeFormatCellDelegate
- (void)formatCellDidClickDownload:(YoutubeFormatCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }
    [[WKDownLoadManager share] addTask:self.tasks[indexPath.row]];
    [self.tabBarController setSelectedIndex:2];
}



/**
 
 duration = 584;
 formats =         (
                 {
         abr = 160;
         acodec = opus;
         ext = webm;
         filesize = 7361376;
         height = 0;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=251&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=audio%2Fwebm&gir=yes&clen=7361376&dur=583.741&lmt=1572933694255023&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6311222&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRgIhAOMiLw2N-4-rFOIHvWWs6zrh-hnk9JZFmaThYh7pF9QDAiEAzRFQarsieKnmxyHgZVycWkij_MqsaEwW6TZWwoeQ5VM%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = none;
     },
                 {
         abr = 128;
         acodec = "mp4a.40.2";
         ext = m4a;
         filesize = 9448438;
         height = 0;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=140&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=audio%2Fmp4&gir=yes&clen=9448438&dur=583.772&lmt=1572933692050264&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6311222&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRAIgTJstZjyYGysVxRTjn7Ii3YY7YI2GqySFEDBSXWxeN3MCIDyYnXtEEgZKfmcVCCqedkpHFstEY9uVmtkRD-bIK0co&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = none;
     },
                 {
         abr = 0;
         acodec = none;
         ext = mp4;
         filesize = 8483519;
         height = 144;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=160&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=8483519&dur=583.716&lmt=1572933706583738&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRQIhANfQEbku3ByoLS6f2kh0wzXjf1SUW5yf6YhMHX2FEwobAiA1j4_3WKpG1Ttn2dBY0UueYySplqH9okTMqF4IwORkOw%3D%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.4d400c";
     },
                 {
         abr = 0;
         acodec = none;
         ext = webm;
         filesize = 8323448;
         height = 144;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=278&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fwebm&gir=yes&clen=8323448&dur=583.716&lmt=1572933714582196&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRgIhAJKrbunGZXmPJQib0Nhuy4qilyc8_bmxYL6Y69Rn5ymjAiEAxiUR6VMcQ1xvF4ut7utKWiBQVopvWKBmWFHq4l3Q6qw%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = vp9;
     },
                 {
         abr = 0;
         acodec = none;
         ext = mp4;
         filesize = 18604740;
         height = 240;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=133&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=18604740&dur=583.716&lmt=1572933706629952&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRAIgGbPuoT_HAj3ty_P--ZYdbY7aIPPjFO_sFg5kLxy8F-UCIH7E_OPYCPQC-z9PDVxUNUR6WRzQfxQAucVrxmIKn03d&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.4d4015";
     },
                 {
         abr = 0;
         acodec = none;
         ext = webm;
         filesize = 19467495;
         height = 240;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=242&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fwebm&gir=yes&clen=19467495&dur=583.716&lmt=1572933714582488&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRAIgbLgYNNJ5dMhU-2ZYhM-qz7gescZfcH2gLHX214KIY-4CIBgH_Yh5m6v1ZGy31KMTU9FF62IiRno-3yPEI94nGn-x&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = vp9;
     },
                 {
         abr = 0;
         acodec = none;
         ext = webm;
         filesize = 35314348;
         height = 360;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=243&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fwebm&gir=yes&clen=35314348&dur=583.716&lmt=1572933714598251&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRQIgUfQjLjPtViPqdSHAbGM0YKOaO6BbCRaBpPFJDTpDqy0CIQChsP-Ce_72Py5qw6qRYuGO5yPFtvtSreEKKVBDorJ0nw%3D%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = vp9;
     },
                 {
         abr = 0;
         acodec = none;
         ext = mp4;
         filesize = 41825043;
         height = 360;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=134&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=41825043&dur=583.716&lmt=1572933706579487&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRQIhANSToc08T2nWEhXLwPyddH2SLz8Q1J6wAcIA6gQmOpNSAiBJhY_r8VQ9gxtZKRU-YyufPb4igc9zPFbB87YinZ5o0A%3D%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.4d401e";
     },
                 {
         abr = 0;
         acodec = none;
         ext = webm;
         filesize = 64166669;
         height = 480;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=244&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fwebm&gir=yes&clen=64166669&dur=583.716&lmt=1572933714582424&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRgIhAPC1cjMjzdXrE6zMc77YjazhTKe9l-HSaN9hIeWljvvRAiEAiubxGF1UHGry9avCdvPjv1pqJ6UTrVFmaG1LsKYrM4o%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = vp9;
     },
                 {
         abr = 0;
         acodec = none;
         ext = mp4;
         filesize = 80026720;
         height = 480;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=135&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=80026720&dur=583.716&lmt=1572933706586704&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRAIgPgjrcOPTSzu4H9Q1ip5VXZ9dxw_-r074QuJK6KohUwkCIHxNRy4VAQiTVbJScJ07397NxZ_YQBX4XH5mXgybBRWc&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.4d401f";
     },
                 {
         abr = 0;
         acodec = none;
         ext = webm;
         filesize = 123880475;
         height = 720;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=247&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fwebm&gir=yes&clen=123880475&dur=583.716&lmt=1572933714588362&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRAIgWAHP2cX_SnLNfa_wq3LqBPLAZgd-960bw_RkdwOHM9kCIEOX_jJLKS-YjMQD-1DviySLrk4CLwQd7o-ugtKI5dci&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = vp9;
     },
                 {
         abr = 0;
         acodec = none;
         ext = mp4;
         filesize = 160679210;
         height = 720;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=136&aitags=133%2C134%2C135%2C136%2C160%2C242%2C243%2C244%2C247%2C278&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=160679210&dur=583.716&lmt=1572933706574295&mt=1572941257&fvip=4&keepalive=yes&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=ALgxI2wwRgIhALbp1atXfC54og-AUigSQMY1L-Dsc4wUje5Z4_UvPiVVAiEA1TqU55vCzLsiaURcc9NPO-xWQemgqAoXnO-VRnUpKT8%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&ratebypass=yes&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.4d401f";
     },
                 {
         abr = 96;
         acodec = "mp4a.40.2";
         ext = mp4;
         filesize = 53935314;
         height = 360;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=18&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&gir=yes&clen=53935314&ratebypass=yes&dur=583.772&lmt=1572938025044991&mt=1572941257&fvip=4&fexp=23842630&c=WEB&txp=5531432&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cmime%2Cgir%2Cclen%2Cratebypass%2Cdur%2Clmt&sig=ALgxI2wwRQIgZ7o172mIiCFJOYWaLRjXKXVFmBZgUvFzFOrALFsmMV8CIQDPCKBqGFNr8FtE8TF0Yb1j0F-yynZuqxHzDfiM0SKyuw%3D%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.42001E";
     },
                 {
         abr = 192;
         acodec = "mp4a.40.2";
         ext = mp4;
         filesize = 0;
         height = 720;
         url = "https://redirector.googlevideo.com/videoplayback?expire=1572962971&ei=Oi7BXd7JOZHMwQH01Y34Bw&ip=181.215.29.239&id=o-AHG680egFyKsJRE7_fFpsQmhSZGE8x5GBJ3yz3NEdAWY&itag=22&source=youtube&requiressl=yes&mm=31%2C26&mn=sn-vgqsrnll%2Csn-q4flrn7y&ms=au%2Conr&mv=m&mvi=3&pl=24&initcwndbps=1956250&mime=video%2Fmp4&ratebypass=yes&dur=583.772&lmt=1572933759418837&mt=1572941257&fvip=4&fexp=23842630&c=WEB&txp=6316222&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cmime%2Cratebypass%2Cdur%2Clmt&sig=ALgxI2wwRQIhAPyhtKyaUuG7CKPIC0lZftyprezq9frQlDUpOL0v_bppAiBEMUDRR569qtlPBDRw5NryOuu7YeEvquFIoljJ7guQew%3D%3D&lsparams=mm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHylml4wRQIhAN_ESAs3Cm8fU_v_RWImjAT50tjku3e7kopfRFtf8A2rAiAPtfwO_rBXjeHaEULMXEQbyZdBL294EjwvVq2YPvp-uA%3D%3D&title=GS%20Warriors%20vs%20Portland%20Trail%20Blazers%20-%20Full%20Game%20Highlights%20%7C%20November%204,%202019-20%20NBA%20Season";
         vcodec = "avc1.64001F";
     }
 );
 music = 1;
 state = completed;
 thumbnail = "https://i.ytimg.com/vi/8sVEZe_RRoc/maxresdefault.jpg";
 title = "GS Warriors vs Portland Trail Blazers - Full Game Highlights | November 4, 2019-20 NBA Season";
 */

@end
