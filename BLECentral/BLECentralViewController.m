//
//  BLECentralViewController.m
//  BLECentral
//
//  Created by NeuroSky on 5/10/13.
//  Copyright (c) 2013 NeuroSky. All rights reserved.
//   72c298ddcf8ac4f54b006883f012803a50f2d5c2

#import "BLECentralViewController.h"

@interface BLECentralViewController ()

@end

static const int PARSER_CODE_POOR_SIGNAL=2;
static const int PARSER_CODE_HEARTRATE = 3;
static const int PARSER_CODE_CONFIGURATION = 4;
static const int PARSER_CODE_RAW = 128;
static const int PARSER_CODE_DEBUG_ONE = 132;
static const int PARSER_CODE_DEBUG_TWO = 133;

static const int PARSER_CODE_EEGPOWER = 131;

static const int PARSER_CODE_ATTENTION = 4;

static const int PST_PACKET_CHECKSUM_FAILED = -2;
static const int PST_NOT_YET_COMPLETE_PACKET = 0;
static const int PST_PACKET_PARSED_SUCCESS = 1;
static const int MESSAGE_READ_RAW_DATA_PACKET = 17;
static const int MESSAGE_READ_DIGEST_DATA_PACKET = 18;
static const int RAW_DATA_BYTE_LENGTH = 2;
static const int EEG_DEBUG_ONE_BYTE_LENGTH = 5;
static const int EEG_DEBUG_TWO_BYTE_LENGTH = 3;
static const int PARSER_SYNC_BYTE = 170;
static const int PARSER_EXCODE_BYTE = 85;
static const int MULTI_BYTE_CODE_THRESHOLD = 127;
static const int PARSER_STATE_SYNC = 1;
static const int PARSER_STATE_SYNC_CHECK = 2;
static const int PARSER_STATE_PAYLOAD_LENGTH = 3;
static const int PARSER_STATE_PAYLOAD = 4;
static const int PARSER_STATE_CHKSUM = 5;


static NSString * const kHandshakeCharacteristicUUID = @"039AFFA0-2C94-11E3-9E06-0002A5D5C51B";

static NSString * const kServiceUUID = @"039AFFF0-2C94-11E3-9E06-0002A5D5C51B";
static NSString * const kCharacteristicUUID = @"039AFFF4-2C94-11E3-9E06-0002A5D5C51B";

Byte payload[256];                              

@implementation BLECentralViewController

@synthesize manager;
@synthesize data;
@synthesize peripheral;
@synthesize DataDisplayLabel;
@synthesize RawDataValue;
@synthesize BufferValue;
@synthesize EKGLineView;
@synthesize StatusLabel;
@synthesize PQLabel;
@synthesize AttentionLabel;
@synthesize TimeLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    //[self centralManagerDidUpdateState:manager];
    parserStatus = PARSER_STATE_SYNC;
    myTime = 0;
    
}

-(void)ButtonClicked:(id)sender{
    [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (IBAction)ConnectButtonClicked:(id)sender {
    NSLog(@"ConnectButtonClicked");
    //[manager connectPeripheral:self.peripheral options:nil];
}

- (IBAction)FindServiceButtonClicked:(id)sender {
    //[peripheral setDelegate:self];
    //[peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}

- (IBAction)StartNotifyButtonClicked:(id)sender {
}


-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
            
            StatusLabel.text = @"Scaning...";
            
            NSLog(@"CBCentralManagerStatePoweredOn");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
            
        default:
            NSLog(@"CM did Change State");
            
            break;
    }
}
//发现周边
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)args_peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    [manager stopScan];
    if (self.peripheral != args_peripheral) {
        self.peripheral = args_peripheral;
        NSLog(@"Connecting to peripheral %@",args_peripheral);
        
        StatusLabel.text = @"Connecting...";
        
        [manager connectPeripheral:args_peripheral options:nil];
    }
    
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Connecting Fail: %@",error);
    StatusLabel.text = @"Connecting Fail";
}

//开始连接周边
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)args_peripheral{
    [data setLength:0];
    NSLog(@"Connected");
    StatusLabel.text = @"Connected";
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    NSLog(@"Start Discover Service!!!");
    StatusLabel.text = @"Discovering Service...";

}
//周边
-(void)peripheral:(CBPeripheral *)args_peripheral didDiscoverServices:(NSError *)error{
     NSLog(@"args_peripheral didDiscoverServices ========");
    
    if (error) {
        NSLog(@"Error discover service: %@",[error localizedDescription]);
        //;
        return;
    }

    for(CBService *service in args_peripheral.services){
        NSLog(@"Service found with UUID: %@",service);
        
        StatusLabel.text = @"Found Service";
        [peripheral discoverCharacteristics:nil forService:service];
        
    
    }

}

-(void)peripheral:(CBPeripheral *)args_peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{

    if (error) {
        NSLog(@"Error discover Character");
        //;
        return; 
    }
    
        for (CBCharacteristic *character in service.characteristics) {
            
            NSLog(@"Characteristic FOUND: %@",character.UUID);
            
            if ([character.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                
                NSLog(@"Successfully Found the Character I wanted!!!");
                
                [peripheral setNotifyValue:YES forCharacteristic:character];
            }
            
            if ([character.UUID isEqual:[CBUUID UUIDWithString:kHandshakeCharacteristicUUID]]) {
                if(character.properties & CBCharacteristicPropertyWrite){
                    char startRealTime[4] = {0x77, 0x00, 0x01, 0xFE};
                    NSData *command = [[NSData alloc] initWithBytes:startRealTime length:4];
                    
                    [peripheral writeValue:command forCharacteristic:character type:CBCharacteristicWriteWithResponse];
                    CBCharacteristic *    commandUUID = character;
                }else {
                    NSLog(@"No write property.");
                }
            }

            
        }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }

    //Byte *b = (Byte *)[characteristic.value bytes];
    
    //[self parseByte:characteristic.value];
    
    myTime += 10000;
    TimeLabel.text = [NSString stringWithFormat:@"T:%d",((int)(myTime/1000000))];
    

    DataDisplayLabel.text = [NSString stringWithFormat:@"Value:%@",characteristic.value];
    
    // Log it
    //NSLog(@"Received: %@", characteristic.value);
}


-(int)parseByte:(NSData *)dataByte{
    int returnValue = 0;
    
    tempbuffer = (Byte*)[dataByte bytes];
    
    for (int i = 0; i < [dataByte length]; i++) {
        chrisbuffer = tempbuffer[i];
        //NSLog(@"LOOP:%d",i);
        
        
        //BufferValue.text = [NSString stringWithFormat:@"ValueXX:%X",chrisbuffer];

        switch (parserStatus) {
                
            case PARSER_STATE_SYNC:
                
                //NSLog(@"Case1");
                if ((chrisbuffer & 0xFF) != PARSER_SYNC_BYTE)break;
                
                parserStatus = PARSER_STATE_SYNC_CHECK;
                break;
                
            case PARSER_STATE_SYNC_CHECK:
                
                //NSLog(@"Case2");
                if ((chrisbuffer & 0xFF) == PARSER_SYNC_BYTE)
                    parserStatus = PARSER_STATE_PAYLOAD_LENGTH;
                else {
                    parserStatus = PARSER_STATE_SYNC;
                }
                break;
                
            case PARSER_STATE_PAYLOAD_LENGTH:
                
                //NSLog(@"Case3");
                payloadLength = (chrisbuffer & 0xFF);
                payloadBytesReceived = 0;
                payloadSum = 0;
                parserStatus = PARSER_STATE_PAYLOAD;
                break;
                
            case PARSER_STATE_PAYLOAD:
                
                //NSLog(@"Case4");
                payload[(payloadBytesReceived++)] = chrisbuffer;
                payloadSum += (chrisbuffer & 0xFF);
                if (payloadBytesReceived < payloadLength) break;
                parserStatus = PARSER_STATE_CHKSUM;
                break;
                
            case PARSER_STATE_CHKSUM:
                
                //NSLog(@"Case5");
                checksum = (chrisbuffer & 0xFF);
                parserStatus = PARSER_STATE_SYNC;
                if (checksum != ((payloadSum ^ 0xFFFFFFFF) & 0xFF)) {
                    returnValue = -2;
                } else {
                    returnValue = 1;
                    [self parsePacketPayload];
                }
                break;
                
            default:
                break;
        }
    }
   
    return returnValue;
    
}

-(void)parsePacketPayload{
    
    //NSLog(@"Packet!!");
    
    int i = 0;
    int extendedCodeLevel = 0;
    int code = 0;
    int valueBytesLength = 0;
    
    int signal = 0; int config = 0; int heartrate = 0; int attention = 0;
    int rawWaveData = 0;
    while (i < payloadLength)
    {
        extendedCodeLevel++;
        
        while (payload[i] == PARSER_EXCODE_BYTE)
        {
            i++;
        }
        
        code = payload[(i++)] & 0xFF;
        
        if (code > MULTI_BYTE_CODE_THRESHOLD) {
            valueBytesLength = payload[(i++)] & 0xFF;
        }
        else {
            valueBytesLength = 1;
        }
        
        if (code == PARSER_CODE_RAW)
        {
            if ((valueBytesLength == RAW_DATA_BYTE_LENGTH) && (YES))
            {
                Byte highOrderByte = payload[i];
                Byte lowOrderByte = payload[(i + 1)];
                
                rawWaveData = [self getRawValue:highOrderByte lowByte:lowOrderByte];
                
                if(rawWaveData > 32768 ) rawWaveData -= 65536;
                
                [EKGLineView addValue:rawWaveData];
                
                RawDataValue.text = [NSString stringWithFormat:@"Value:%d",rawWaveData];
                
            }
            i += valueBytesLength;
        } else {
            switch (code)
            {
                case PARSER_CODE_POOR_SIGNAL:
                    signal = payload[i] & 0xFF;
                    i += valueBytesLength;
                    //Log.i(TAG, "PARSER_CODE_POOR_SIGNAL" + signal);
                    
                    PQLabel.text = [NSString stringWithFormat:@"PQ:%d",signal];
                    
                    break;
                    
                case PARSER_CODE_EEGPOWER:
                    
                    i += valueBytesLength;
                    
                    break;
                case PARSER_CODE_CONFIGURATION:
                    config = payload[i] & 0xFF;
                    i += valueBytesLength;
                    
                    AttentionLabel.text = [NSString stringWithFormat:@"Att:%d,T:%d",config,((int)(myTime/1000000))];
                    
                    break;
                case PARSER_CODE_HEARTRATE:
                    heartrate = payload[i] & 0xFF;
                    i += valueBytesLength;
                    
                    //Log.i(TAG, "PARSER_CODE_HEARTRATE" + heartrate);
                    //AttentionLabel.text = [NSString stringWithFormat:@"Att:%d,T:%d",heartrate,((int)(myTime/1000000))];
                    
                    break;
                case PARSER_CODE_DEBUG_ONE:
                    if (valueBytesLength == EEG_DEBUG_ONE_BYTE_LENGTH) {
                        i += valueBytesLength;
                    }
                    break;
                case PARSER_CODE_DEBUG_TWO:
                    if (valueBytesLength == EEG_DEBUG_TWO_BYTE_LENGTH) {
                        i += valueBytesLength;
                    }
                    break;
            }
        }
    }
    parserStatus = PARSER_STATE_SYNC;
}

-(int)getRawValue:(Byte)highByte lowByte:(Byte)lowByte{
    
    int hi = (int)highByte;
    int lo = ((int)lowByte) & 0xFF;
    
    int return_value = (hi<<8) | lo;

    return return_value;
}


-(void)peripheral:(CBPeripheral *)args_peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        
    }
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notifying Begin");
        //[peripheral readValueForCharacteristic:characteristic];
    } else {
        NSLog(@"Notifying Stop");
        //[manager cancelPeripheralConnection:peripheral];
    }




}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


















@end
