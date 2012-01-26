unit LunarCalendarDataGenerator;

interface

uses
  SysUtils,
  hjLunarDateType ,hjLunarDateConverter, CalendarDataGenerator, CalendarCommons;

const
  // �ѱ� ���̸�
  LunarKoreanMonthName: array[1..12] of string = (
      '����', '�̿�', '���', '���', '����',   '����'
    , 'ĥ��', '�ȿ�', '����', '�ÿ�', '������', '����'
  );
  LunarKoreanHalfMonth: string      = '����';
  LunarKoreanEndOfTheMonth: string  = '�׹�';

type
  TLunarDispDays = array of word;

  TLunarCalendarSource = class(TCalendarSource)
  private
    FIndex: Integer;
    FDisplayDaysType: TLunarDaysDisplayType;
    FDisplayDays: TLunarDispDays;
  public
    constructor Create(ADispType: TLunarDaysDisplayType);

    procedure First; override;
    procedure Next; override;
    function HasNext: Boolean; override;
    function Day: Word;

    property DisplayDaysType: TLunarDaysDisplayType read FDisplayDaysType;
  end;

  TLunarCalendarDataGenerator = class(TCalendarDataGenerator)
  private
    FCurrentDate: TSolarDateRec;
    FYear: Word;
    FIndexOfMonth: Integer;   // ���� �ε���(����ȣ�� �ٸ�)

    function GetLunarDateRec(AYear: Word; AIndexOfMonth: Integer; ADay: Word): TLunarDateRec;
    function GetSummury(ADispType: TLunarDaysDisplayType; ALunar: TLunarDateRec): string;
  protected
    procedure Initialize; override;
  public
    function Next: TCalendarData; override;
  end;

implementation

uses
  StrUtils;

{ TLunarCalendarSource }

constructor TLunarCalendarSource.Create(ADispType: TLunarDaysDisplayType);
  procedure SetData(const Args: array of word);
  var
    I: Integer;
  begin
    SetLength(FDisplayDays, Length(Args));
    for I := 0 to Length(Args) - 1 do
      FDisplayDays[I] := Args[I];
  end;
begin
  FDisplayDaysType := ADispType;

  case FDisplayDaysType of
    lddt5:    SetData([1, 5, 10, 15, 20, 25, 99]);
    lddt10:   SetData([1, 10, 20, 99]);
    lddt15:   SetData([1, 15, 99]);
    lddtKor:  SetData([1, 5, 10, 15, 20, 25, 99]);
  end;
end;

function TLunarCalendarSource.Day: Word;
begin
  Result := 0;
  if FIndex < Length(FDisplayDays) then
    Result := FDisplayDays[FIndex];
end;

procedure TLunarCalendarSource.First;
begin
  FIndex := 0;
end;

function TLunarCalendarSource.HasNext: Boolean;
begin
  Result := FIndex < Length(FDisplayDays);
end;

procedure TLunarCalendarSource.Next;
begin
  Inc(FIndex);
end;

{ TLunarCalendarDataGenerate }

procedure TLunarCalendarDataGenerator.Initialize;
begin
  FCurrentDate := DateRec(FStartOfRange, 1, 1);

  FYear   := FStartOfRange;
  FIndexOfMonth  := 1;
end;

function TLunarCalendarDataGenerator.GetSummury(
  ADispType: TLunarDaysDisplayType; ALunar: TLunarDateRec): string;
begin
  case ADispType of
  lddt5..lddt15:
    Result := Format('%s%d.%d', [IfThen(ALunar.IsLeapMonth, '(��)', ''), ALunar.Month, ALunar.Day]);
  lddtKor:
    begin
      case ALunar.Day of
      1:      Result := IfThen(ALunar.IsLeapMonth, '��', '') + LunarKoreanMonthName[ALunar.Month];
      15:     Result := '����';
      5, 10, 20, 25:
        Result := Format('%s%d.%d', [IfThen(ALunar.IsLeapMonth, '(��)', ''), ALunar.Month, ALunar.Day]);
      else    Result := '�׹�';
      end;
    end;
  end;
end;

function TLunarCalendarDataGenerator.GetLunarDateRec(AYear: Word;
  AIndexOfMonth: Integer; ADay: Word): TLunarDateRec;
begin
  Result.Year := FYear;

  FLunarDateConvertor.GetLunarMonthFromMonthIndex(FYear, AIndexOfMonth, Result.Month, Result.IsLeapMonth);

  if ADay > 30 then
    Result.Day := FLunarDateConvertor.GetLunarDaysOfMonth(FYear, Result.Month, Result.IsLeapMonth)
  else
    Result.Day := ADay;
end;

function TLunarCalendarDataGenerator.Next: TCalendarData;
var
  Lunar: TLunarDateRec;
  Solar: TSolarDateRec;
  Source: TLunarCalendarSource;
begin
  Result := nil;

  Source := TLunarCalendarSource(FCalendarSource);

  // Source�� �����Ͱ� ������ ������(Month ����)
  if not Source.HasNext then
  begin
    Inc(FIndexOfMonth);
    FCalendarSource.First;
  end;

  if not FLunarDateConvertor.HasLunarMonthData(FYear, FIndexOfMonth) then
  begin
    Inc(FYear);
    FIndexOfMonth := 1;
  end;

  if FYear > FEndOfRange then
    Exit;

  Lunar := GetLunarDateRec(FYear, FIndexOfMonth, Source.Day);
  Solar := FLunarDateConvertor.LunarToSolar(Lunar);

  Result := FCalendarData.SetData(Solar, Lunar, GetSummury(Source.DisplayDaysType, Lunar), '');

  Source.Next;
end;

end.
