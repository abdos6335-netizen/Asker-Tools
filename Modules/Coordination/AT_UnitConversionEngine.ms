/* Asker Tools - 3ds Max Unit Conversion
   Converts explicitly unit-tagged rule values into 3ds Max internal master units.
*/
global AT_UnitConversionEngine
struct AT_UnitConversionResult (
 valid=false, sourceValue=undefined, sourceUnit="", systemValue=undefined,
 systemUnit="3dsMaxMasterUnit", reason="UNCONVERTED"
)
struct AT_UnitConversionEngineStruct (
 version="0.1.0", lastErrors=#(),
 fn suffixForUnit unit = (
  case (toLower unit) of (
   "mm":"mm"
   "millimeter":"mm"
   "millimeters":"mm"
   "cm":"cm"
   "centimeter":"cm"
   "centimeters":"cm"
   "m":"m"
   "meter":"m"
   "meters":"m"
   "km":"km"
   "kilometer":"km"
   "kilometers":"km"
   "in":"\""
   "inch":"\""
   "inches":"\""
   "ft":"'"
   "foot":"'"
   "feet":"'"
   "system":""
   "master":""
   default:undefined
  )
 ),
 fn toSystemUnits value unit = (
  local result=AT_UnitConversionResult sourceValue:value sourceUnit:unit
  if (classOf value!=Integer and classOf value!=Float) or value<0 then (result.reason="INVALID_NUMERIC_VALUE"; append lastErrors #(value,unit,result.reason); return result)
  local suffix=suffixForUnit unit
  if suffix==undefined then (result.reason="UNSUPPORTED_LENGTH_UNIT"; append lastErrors #(value,unit,result.reason); return result)
  try (
   if suffix=="" then result.systemValue=value
   else result.systemValue=units.decodeValue ((value as string)+suffix)
   result.valid=true; result.reason="CONVERTED_TO_3DS_MAX_MASTER_UNITS"
  ) catch (
   result.reason="UNIT_CONVERSION_FAILED"
   append lastErrors #(value,unit,getCurrentException())
  )
  result
 ),
 fn clearErrors = (lastErrors=#(); true)
)
AT_UnitConversionEngine=AT_UnitConversionEngineStruct()
