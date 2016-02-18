//
//  BLECentralViewController.h
//  BLECentral
//
//  Created by NeuroSky on 5/10/13.
//  Copyright (c) 2013 NeuroSky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "LineGraphView.h"

@interface BLECentralViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>{
    
    Byte *tempbuffer;
    Byte chrisbuffer;
    int parserStatus;
    int payloadLength;
    int payloadBytesReceived;
    int payloadSum;
    int checksum;
    
    int myTime;
    


}

@property(nonatomic,strong)CBCentralManager *manager;
@property(nonatomic,strong)NSMutableData *data;
@property(nonatomic,strong)CBPeripheral *peripheral;
- (IBAction)ButtonClicked:(id)sender;
- (IBAction)ConnectButtonClicked:(id)sender;
- (IBAction)FindServiceButtonClicked:(id)sender;
- (IBAction)StartNotifyButtonClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *DataDisplayLabel;
@property (weak, nonatomic) IBOutlet UILabel *RawDataValue;
@property (weak, nonatomic) IBOutlet UILabel *BufferValue;
@property (weak, nonatomic) IBOutlet LineGraphView *EKGLineView;
@property (weak, nonatomic) IBOutlet UILabel *StatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *PQLabel;
@property (weak, nonatomic) IBOutlet UILabel *AttentionLabel;
@property (weak, nonatomic) IBOutlet UILabel *TimeLabel;

@end
