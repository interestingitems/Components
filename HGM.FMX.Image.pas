unit HGM.FMX.Image;

interface

uses
  System.Classes, System.Types, System.SysUtils, FMX.Forms, FMX.Graphics, FMX.Objects, System.Generics.Collections;

type
  TBitmapCacheItem = class
  private
    FImage: TBitmap;
    FUrl: string;
    FLoaded: Boolean;
    procedure SetImage(const Value: TBitmap);
    procedure SetLoaded(const Value: Boolean);
    procedure SetUrl(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;
    property Image: TBitmap read FImage write SetImage;
    property Url: string read FUrl write SetUrl;
    property Loaded: Boolean read FLoaded write SetLoaded;
  end;

  TBitmapCache = TArray<TBitmapCacheItem>;

  TBitmapHelper = class helper for TBitmap
  private
    class var
      DroppingCache: Boolean;
    class function AppendCache: TBitmapCacheItem;
    class procedure DropCacheLimit;
    class function ExistsCache(const Url: string; var Target: TBitmap): Boolean;
  public
    class var
      PictureCache: TBitmapCache;
      LoadCounter: Integer;
      LoadCounterLimit: Integer;
      CacheSize: Integer;
      GlobalUseCache: Boolean;
    procedure LoadFromUrl(const Url: string; UseCache: Boolean = True);
    procedure LoadFromUrlAsync(const Url: string; UseCache: Boolean = True);
    procedure LoadFromResource(ResName: string);
    class procedure DropCache;
    class procedure SetLoaded(Url: string);
    class procedure DeleteCache(Url: string);
    class function CreateFromUrl(const Url: string; UseCache: Boolean = True): TBitmap;
    class function CreateLazy(const Url: string; FirstAsDefault: Boolean = False; UseCache: Boolean = True): TBitmap;
    class function CreateFromResource(ResName: string; Url: string = ''): TBitmap;
  end;

  TImageHelper = class helper for TImage
    procedure LoadFromUrl(const Url: string; AfterLoaded: TProc<TImage> = nil);
  end;

implementation

uses
  HGM.Common.Download;

{ TBitmapHelper }

class function TBitmapHelper.AppendCache: TBitmapCacheItem;
begin
  DropCacheLimit;
  Result := TBitmapCacheItem.Create;
  SetLength(PictureCache, Length(PictureCache) + 1);
  PictureCache[High(PictureCache)] := Result;
end;

class procedure TBitmapHelper.DropCache;
var
  i: Integer;
begin
  for i := Low(PictureCache) to High(PictureCache) do
    PictureCache[i].Free;
  SetLength(PictureCache, 0);
end;

class procedure TBitmapHelper.DropCacheLimit;
begin
  if GlobalUseCache and not DroppingCache then
  begin
    DroppingCache := True;
    try
      while Length(PictureCache) > CacheSize do
      begin
        PictureCache[0].Free;
        Delete(PictureCache, 0, 1);
      end;
    except
    end;
    DroppingCache := False;
  end;
end;

class function TBitmapHelper.CreateFromResource(ResName, Url: string): TBitmap;
var
  Item: TBitmapCacheItem;
begin
  if GlobalUseCache then
  begin
    Item := AppendCache;
    Item.Image := TBitmap.Create;
    Item.Loaded := True;
    Item.Url := Url;
    Item.Image.LoadFromResource(ResName);
    Result := Item.Image;
  end
  else
  begin
    Result := TBitmap.Create;
    Result.LoadFromResource(ResName);
  end;
end;

class function TBitmapHelper.CreateFromUrl(const Url: string; UseCache: Boolean): TBitmap;
var
  Item: TBitmapCacheItem;
begin
  if GlobalUseCache and UseCache and ExistsCache(Url, Result) then
    Exit;
  if GlobalUseCache then
  begin
    Item := AppendCache;
    Item.Image := TBitmap.Create;
    Item.Loaded := True;
    Item.Url := Url;
    Item.Image.LoadFromUrl(Url, False);
    Result := Item.Image;
  end
  else
  begin
    Result := TBitmap.Create;
    Result.LoadFromUrl(Url, False);
  end;
end;

class function TBitmapHelper.CreateLazy(const Url: string; FirstAsDefault: Boolean; UseCache: Boolean): TBitmap;
var
  Item: TBitmapCacheItem;
begin
  if GlobalUseCache and UseCache and ExistsCache(Url, Result) then
    Exit;
  Item := AppendCache;
  Item.Image := TBitmap.Create;
  Item.Url := Url;
  if FirstAsDefault then
  begin
    if Length(PictureCache) > 1 then
      Item.Image.Assign(PictureCache[0].Image);
  end;
  Result := Item.Image;
end;

class procedure TBitmapHelper.DeleteCache(Url: string);
var
  i: Integer;
begin
  for i := Low(PictureCache) to High(PictureCache) do
  begin
    if PictureCache[i].Url = Url then
    begin
      PictureCache[i].Free;
      Delete(PictureCache, i, 1);
      Exit;
    end;
  end;
end;

class function TBitmapHelper.ExistsCache(const Url: string; var Target: TBitmap): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(PictureCache) to High(PictureCache) do
  begin
    if PictureCache[i].Url = Url then
    begin
      Target := PictureCache[i].Image;
      Exit(True);
    end;
  end;
end;

procedure TBitmapHelper.LoadFromResource(ResName: string);
var
  Mem: TResourceStream;
begin
  Mem := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    Self.LoadFromStream(Mem);
  finally
    Mem.Free;
  end;
end;

procedure TBitmapHelper.LoadFromUrl(const Url: string; UseCache: Boolean);
var
  Mem: TMemoryStream;
  Item: TBitmapCacheItem;
  Cache: TBitmap;
begin
  if GlobalUseCache and UseCache and ExistsCache(Url, Cache) then
  begin
    Self.Assign(Cache);
    Exit;
  end;
  Mem := TDownload.Get(Url);
  try
    try
      if Mem.Size > 0 then
      begin
        TThread.Synchronize(nil,
          procedure
          begin
            try
              Self.LoadFromStream(Mem);
            except
            end;
          end);
        if GlobalUseCache and UseCache then
        begin
          Item := AppendCache;
          Item.Image := Self;
          Item.Url := Url;
          Item.Loaded := True;
        end;
      end;
    finally
      Mem.Free;
    end;
  except
  end;
end;

procedure TBitmapHelper.LoadFromUrlAsync(const Url: string; UseCache: Boolean);
begin
  Inc(LoadCounter);
  TThread.CreateAnonymousThread(
    procedure
    begin
      while LoadCounter > LoadCounterLimit do
        TThread.Sleep(500);
      try
        Self.LoadFromUrl(Url, UseCache);
      except
      end;
      Dec(LoadCounter);
    end).Start;
end;

class procedure TBitmapHelper.SetLoaded(Url: string);
var
  i: Integer;
begin
  for i := Low(PictureCache) to High(PictureCache) do
    if PictureCache[i].Url = Url then
      PictureCache[i].Loaded := True;
end;

{ TImageHelper }

procedure TImageHelper.LoadFromUrl(const Url: string; AfterLoaded: TProc<TImage>);
var
  Thread: TThread;
begin
  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      BMP: TBitmap;
    begin
      try
        if not TThread.Current.CheckTerminated then
        begin
          BMP := TBitmap.CreateFromUrl(Url);
          if not TThread.Current.CheckTerminated then
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                Self.Bitmap.Assign(BMP);
              end);
            if not TThread.Current.CheckTerminated then
            begin
              if Self.Bitmap.IsEmpty then
              begin
                if TBitmap.GlobalUseCache then
                  TBitmap.DeleteCache(Url);
                BMP.LoadFromUrl(Url);
                if not TThread.Current.CheckTerminated then
                begin
                  TThread.Synchronize(nil,
                    procedure
                    begin
                      Self.Bitmap.Assign(BMP);
                    end);
                end;
              end;
            end;
          end;
          if not TBitmap.GlobalUseCache then
            BMP.Free;
        end;
      except
      end;
      if Assigned(AfterLoaded) then
        AfterLoaded(Self);
    end);
  Thread.Start;
end;

{ TBitmapCacheItem }

constructor TBitmapCacheItem.Create;
begin
  inherited;
  Image := nil;
  Loaded := False;
  Url := '';
end;

destructor TBitmapCacheItem.Destroy;
begin
  if Assigned(Image) then
    Image.Free;
  inherited;
end;

procedure TBitmapCacheItem.SetImage(const Value: TBitmap);
begin
  FImage := Value;
end;

procedure TBitmapCacheItem.SetLoaded(const Value: Boolean);
begin
  FLoaded := Value;
end;

procedure TBitmapCacheItem.SetUrl(const Value: string);
begin
  FUrl := Value;
end;

initialization
  TBitmap.DroppingCache := False;
  TBitmap.CacheSize := 60;
  TBitmap.LoadCounterLimit := 20;
  TBitmap.GlobalUseCache := False;

finalization
  TBitmap.DropCache;

end.

