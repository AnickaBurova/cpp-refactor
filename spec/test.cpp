#pragma once

#include "inf-element.h"

namespace s104
{
	class CNameOfFile : public IInformationElement
	{
		uint16_t mValue;
		std::string mText;
		std::vector<char> mVec;
		uint  mArray[22];
	public:
		// comment {
		CNameOfFile()
		{}
		CNameOfFile(uint16_t value)
			:mValue(value)
		{
		};
		/*  {   */

		CNameOfFile(std::istream& reader)
			:mValue(read_value<uint16_t>(reader))
		{
		}
		CREATE_ANY(unsigned short,GetValue,mValue,0,0xffff)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Name of file: " << GetValue();
		}

		int24_t value;

		size_t GetFieldsSize()const
		{
			return +sizeof(mValue)+sizeof(mText)+mVec.size()+1+sizeof(mArray)+3;
		}
	};


	class CNameOfSection : public IInformationElement
	{
		uint16_t mValue;
	public:
		CNameOfSection()
		{}
		CNameOfSection(uint16_t value)
			:mValue(value)
		{
		};

		CNameOfSection(std::istream& reader)
			:mValue(read_value<uint16_t>(reader))
		{
		}
		CREATE_ANY(unsigned short,GetValue,mValue,0,0xffff)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Name of section: " << GetValue();
		}

		size_t GetFieldsSize()const
		{
			return 2;
		}
	};

	class CLengthOfFileOrSection : public IInformationElement
	{
	 	uint24_t mValue;
	public:
		CLengthOfFileOrSection()
		{}
		CLengthOfFileOrSection(uint32_t value)
			:mValue(value)
		{
		};

		CLengthOfFileOrSection(std::istream& reader)
			:mValue(read_value<uint24_t>(reader))
		{
		}
		CREATE_ANY(uint32_t,GetValue,mValue.value,0,0xffffff)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Length of file or section: " << GetValue();
		}

	};

	template < >
	struct _get_size_of_ie<CLengthOfFileOrSection>
	{
		size_t operator()(const CLengthOfFileOrSection&)const
		{
			return 3;
		}
	};



	class CFileReadyQualifier : public IInformationElement
	{
		uint8_t mValue;
	public:
		CFileReadyQualifier()
		{}
		CFileReadyQualifier(int value, bool negativeConfirm)
			:mValue(CBitBuilder<0x7f>(value)
					.Set<0x80>(negativeConfirm)
					.GetValue())
		{
		};

		CFileReadyQualifier(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(int,GetValue,mValue,0,0x7f)
		CREATE_BOOL(IsNegativeConfirm,mValue,0x80)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "File ready qualifier: " << GetValue()
				<< ", negative confirm: "  << IsNegativeConfirm() ;
		}

	};

	class CSectionReadyQualifier : public IInformationElement
	{
		uint8_t mValue;
	public:
		CSectionReadyQualifier()
		{}
		CSectionReadyQualifier(int value, bool sectionNotReady)
			:mValue(CBitBuilder<0x7f>(value) .Set<0x80>(sectionNotReady) .GetValue())
		{
		};

		CSectionReadyQualifier(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(int,GetValue,mValue,0,0x7f)
		CREATE_BOOL(IsSectionNotReady,mValue,0x80)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Section ready qualifier: "<< GetValue() << ", section not ready: "  << IsSectionNotReady() ;
		}

	};

	ENUMS(EActionCode
			,Default
			,SelectFile
			,RequestFile
			,DeactivateFile
			,DeleteFile
			,SelectSection
			,RequestSection
			,DeactivateSection
		)

	ENUMS(EFaultCode
			,Default
			,RequestedMemorySpaceNA
			,ChecksumFailed
			,UnexpectedCommunicationService
			,UnexpectedNameOfFile
			,UnexpectedNameOfSection
		)

	class CSelectAndCallQualifier : public IInformationElement
	{
		uint8_t mValue;
	public:
		CSelectAndCallQualifier()
		{}
		CSelectAndCallQualifier(EActionCode action, EFaultCode faultCode)
			:mValue(CBitBuilder<0x0f>((int)action) .Set<0xf0>((int)faultCode << 4) .GetValue())
		{
		};

		CSelectAndCallQualifier(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(EActionCode,GetAction,mValue,0,0x0f)
		CREATE_ANY(EFaultCode,GetFault,mValue,4,0x0f)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Select and call qualifier, action: "  << to_string(GetAction()) << ", fault code: "  << to_string(GetFault()) ;
		}

	};

	ENUMS(ELastAction
			,NotUsed
			,FileTransferWithoutDeactivation
			,FileTransferWithDeactivation
			,SectionTransferWithoutDeactivation
			,SectionTransferWithDeactivation
		)


	class CLastSectionOrSegmentQualifier : public IInformationElement
	{
		uint8_t mValue;
	public:
		CLastSectionOrSegmentQualifier()
		{}
		CLastSectionOrSegmentQualifier(ELastAction action)
			:mValue((int)action)
		{
		};

		CLastSectionOrSegmentQualifier(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(ELastAction,GetValue,mValue,0,0xff)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Last section or segment qualifier: "  << to_string(GetValue()) ;
		}

	};

	ENUMS(EAcknowledge
			,NotUsed
			,PositiveAckOfFileTransfer
			,NegativeAckOfFileTransfer
			,PositiveAckOfSectionTransfer
			,NegativeAckOfSectionTransfer
		)

	class CAckFileOrSectionQualifier : public IInformationElement
	{
		uint8_t mValue;
	public:
		CAckFileOrSectionQualifier()
		{}
		CAckFileOrSectionQualifier(EAcknowledge ack, EFaultCode fault)
			:mValue(CBitBuilder<0x0f>((int)ack) .Set<0xf0>((int)fault << 4) .GetValue())
		{
		};

		CAckFileOrSectionQualifier(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(EAcknowledge,GetAcknowledge,mValue,0,0x0f)
		CREATE_ANY(EFaultCode,GetFault,mValue,4,0x0f)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Acknowledge file or section qualifier, acknowledgement: "  << to_string(GetAcknowledge()) << ", fault : "  << to_string(GetFault());
		}

	};



	class CFileSegment : public IInformationElement
	{
		std::vector<char> mSegment;
	public:
		CFileSegment()
		{}		CFileSegment(const std::vector<char>& data)
			: mSegment(data)
		{

		}

		CFileSegment(std::vector<char>&& data)
			: mSegment(std::move(data))
		{

		}
		CFileSegment(const char* segment, int length)
			:mSegment(segment,segment+length)
		{};

		CFileSegment(std::istream& reader)
		{
			int length = read_value<uint8_t>(reader);
			mSegment.resize(length);
			reader.read((char*)mSegment.data(),length);
		}

		const std::vector<char>& GetSegment()const {return mSegment;}


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer, (uint8_t)mSegment.size());
			writer.write(mSegment.data(),mSegment.size());
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "File segment of length: "  << GetSegment().size() ;
		}

	};

	template < >
	struct _get_size_of_ie<CFileSegment>
	{
		size_t operator()(const CFileSegment& seg)const
		{
			return seg.GetSegment().size() + 1;
		}
	};



	class CStatusOfFile : public IInformationElement
	{
		uint8_t mValue;
	public:
		CStatusOfFile()
		{}
		CStatusOfFile(int status, bool lastFileOfDirectory, bool nameDefinesDirectory, bool transferIsActive)
			:mValue(CBitBuilder<0x1f>(status)
					.Set<0x20>(lastFileOfDirectory)
					.Set<0x40>(nameDefinesDirectory)
					.Set<0x80>(transferIsActive)
					.GetValue())
		{
		};

		CStatusOfFile(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(int,GetStatus,mValue,0,0x1f)
		CREATE_BOOL(IsLastFileOfDirectory,mValue,0x20)
		CREATE_BOOL(IsNameDefinesDirectory,mValue,0x40)
		CREATE_BOOL(IsTransferIsActive,mValue,0x80)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Status of file: "  << GetStatus()
				<< ", last file of directory: "  << IsLastFileOfDirectory()
				<< ", name defines directory: "  << IsNameDefinesDirectory()
				<< ", transfer is active: " << IsTransferIsActive() ;
		}

	};


	class CChecksum : public IInformationElement
	{
		uint8_t mValue;
	public:
		CChecksum()
		{}
		CChecksum(uint8_t value)
			:mValue(value)
		{
		};

		CChecksum(std::istream& reader)
			:mValue(read_value<uint8_t>(reader))
		{
		}

		CREATE_ANY(uint8_t,GetValue,mValue,0,0xff)


		virtual void Encode(std::ostream& writer)const
		{
			write_value(writer,mValue);
		}

		virtual void WriteToString(std::ostream& stringer)const
		{
			stringer << "Checksum: "  << GetValue() ;
		}

	};

}
