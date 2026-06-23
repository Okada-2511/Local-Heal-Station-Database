----------SYNONYM----------
--Synonmyn 1 Tên đồng nghĩa đơn thuốc
Create Synonym DT
for DonThuoc
--Kiểm thử
Select * 
from DT
--Synomym 2 Tên đồng nghĩa Hồ sơ khám
Create Synonym HSK
for HoSoKham
--Kiểm thử
Select * 
FROM HSK
--Synonym 3 Tên đồng nghĩa cho bệnh nhân
Create Synonym BN
for BenhNhan
--Kiểm thử
Select * 
from BN
--Synonym 4 Tên đồng nghĩa cho hóa đơn
Create Synonym HD
for HoaDon
--Kiểm thử
select * 
from HD

-----INDEX----------

--Tạo index tên bệnh nhân
Create index idx_tenbenhnhan
On BenhNhan(TenBN,HoBN)
include (NgaySinhBN,GioiTinh,DiaChi,SDT)


--Kiểm thử
Select * from BenhNhan
where TenBN like N'P%'


--Tạo index ngày hóa đơn
create index idx_Ngayhoadon
On HoaDon(NgayLapHD)
where TrangThai = N'Chưa thanh toán'

--Kiểm thử
select * from HoaDon
where NgayLapHD = '2025-5-18' 
	  and TrangThai = N'Chưa thanh toán'

--Tạo index ngày khám bệnh
Create index idx_NgayKhamBenh
On HoSoKham(NgayKham)

--Kiểm thử
Select * from HoSoKham
where NgayKham = '2025-5-18'

--Tạo index tên thuốc
create index idx_tenthuoc
on Thuoc(TenThuoc)
INCLUDE (DonViTinh, TrongDanhMucBHYT,DonGiaBan,HangSX)

--Kiểm thử
select * from Thuoc
where TenThuoc like 'Vitamin%'



--Tạo Index theo ngày nhập thuốc
Create index idx_NgayNhapThuoc
on PhieuNhap(NgayNhap DESC)


--Kiểm thử
select * from PhieuNhap
where NgayNhap = '2025-3-5'

--Tạo index theo hạn sử dụng của thuốc
CREATE INDEX idx_HSDThuoc
ON KhoThuoc (HSD ASC) 
INCLUDE (MaThuoc, MaLo, SoLuongTon) 
WHERE SoLuongTon > 0



-----VIEW-----------

--View xem danh sách bệnh nhân
create view vw_danhsachbenhnhan
as
	select MaBN,HoBN+' '+TenBN as HoTenBN,NgaySinhBN,GioiTinh,DiaChi,SDT
	from BenhNhan

--Kiểm thử
select * 
from vw_danhsachbenhnhan

--View xem danh sach hồ sơ bệnh với những bệnh nhân được chuẩn đoán hạ đường huyết
create view vw_danhsachhosokham
as 
	select MaHS,NgayKham,ChuanDoan,KetLuan,MaNV,MaBN
	from HoSoKham
	where ChuanDoan like N'Hạ đường huyết%'

--Kiểm thử
select * from vw_danhsachhosokham

--View xem số lượng tồn của Thuốc
create view vw_soluongtonthuoc
as
	select TenThuoc,
		Sum(SoLuongTon) as TongTonKho,
		HangSX,
		HSD
	from KhoThuoc as KT
	join Thuoc as T
	on KT.MaThuoc = T.MaThuoc
	group by TenThuoc,HangSX,HSD

--Kiểm thử
select * from vw_soluongtonthuoc

--View xem thuốc có hạn sử dụng < 90 ngày
create view vw_thuocsaphethan 
AS
	SELECT T.TenThuoc, MaLo, HSD, SoLuongTon,
	DATEDIFF(DAY, GETDATE(), HSD) as SoNgayConLai
	FROM KhoThuoc as K
	JOIN Thuoc as T 
	ON K.MaThuoc = T.MaThuoc
	WHERE 
	SoLuongTon > 0 and
	HSD <= Dateadd(Day,90,Getdate())

--Kiểm thử
select * from vw_thuocsaphethan

-- Hoặc ta có thể lồng view
create view vw_ChiTietThuocSapHetHan
as
    select 
        TenThuoc, 
        TongTonKho, 
        HSD, 
        DATEDIFF(DAY, GETDATE(), HSD) as SoNgayConLai
    from vw_soluongtonthuoc -- Lấy view trên dùng
		WHERE HSD <= Dateadd(Day,90,Getdate())

--Kiểm thử
select * 
from vw_thuocsaphethan

--View đếm số bệnh nhân Nam,Nữ
create view vw_demsobenhnhan
as
	select GioiTinh,COUNT(MaBN) as TongSo
	from BenhNhan
	group by GioiTinh

--Kiểm thử 
select * from vw_demsobenhnhan

--View tổng hợp số lượng thuốc sắp hết hạn sử dụng
CREATE VIEW vw_TongHopThuocSapHetHan
AS
    SELECT 
        T.TenThuoc,
        SUM(K.SoLuongTon) as TongSoLuongCanBanGap, -- Cộng dồn số lượng
        COUNT(K.MaLo) as SoLoBiAnhHuong,           -- Đếm xem bao nhiêu lô bị dính
        MIN(K.HSD) as HanSuDungGanNhat             -- Lấy ngày hết hạn gần nhất để cảnh báo
    FROM KhoThuoc as K
    JOIN Thuoc as T ON K.MaThuoc = T.MaThuoc
    WHERE DATEDIFF(DAY, GETDATE(), K.HSD) <= 300
    GROUP BY T.TenThuoc;


--View xem Danh sách tiêm chủng
create view vw_danhsachtiemchung
as
	select  PTC.MaBN,HoBN+' '+TenBN as HoTenBN,BN.NgaySinhBN,
			HoNV+' '+TenNV as NguoiPhuTrach, 
			NgayTiem
	from PhieuTiemChung AS PTC
	JOIN BenhNhan as BN
	on PTC.MaBN = BN.MaBN
	JOIN NhanVien as NV
	on PTC.MaNV = NV.MaNV

--Kiểm thử
select * from vw_danhsachtiemchung



--View xem danh sách tiêm chủng cho đối tượng dưới 3 tuổi
create view vw_dstiemchungduoi3tuoi
as
    select MaBN,HoTenBN,NgaySinhBN,
		   case
               -- Nếu sinh trong cùng năm  thì tính bằng Tháng
               when YEAR(GETDATE()) - YEAR(NgaySinhBN) = 0
               then CAST(DATEDIFF(MONTH, NgaySinhBN, GETDATE()) as nvarchar) + N' tháng'
			   --ngược lại là tuổi
               else CAST(YEAR(GETDATE()) - YEAR(NgaySinhBN) as nvarchar) + N' tuổi'
           end as DoTuoi,
		   NguoiPhuTrach,NgayTiem
    from vw_danhsachtiemchung --lồng view trên
    where NgaySinhBN > DATEADD(YEAR, -3, GETDATE())

--Kiểm thử
select * from vw_dstiemchungduoi3tuoi
--view 8 view xem MaPhiecTC,HoTen,Tuoi,CanNang,TenVaccine,MucDoPhanUng
create view vw_xemcannangtuoimucdophanung
as
	select
		PTC.MaPhieuTC,
		bn.HoBN + ' ' + bn.TenBN AS HoTen,
		DATEDIFF(YEAR, bn.NgaySinhBN, PTC.NgayTiem) AS Tuoi,
		PTC.CanNang,
		v.TenVaccine,
		CTPT.MucDoPhanUng 
   from PhieuTiemChung as PTC
	JOIN CT_PhieuTiemChung CTPT ON PTC.MaPhieuTC = CTPT.MaPhieuTC
	JOIN BenhNhan bn ON PTC.MaBN = bn.MaBN
	JOIN Lo_Vaccine l ON CTPT.MaLoVaccine = l.MaLoVaccine
	JOIN Vaccine v ON l.MaVaccine = v.MaVaccine

--Kiểm thử
select * from vw_xemcannangtuoimucdophanung
order by CanNang ASC
-----FUNCTION-------
--Hàm xem danh sách các chi tiết đơn thuốc gồm MaDT,MaThuoc,SoLuong,Cachdung
--với tham số truyền vào là mã đơn thuốc
create function f_chithietdonthuoctheomadon(@MaDT char(6))
returns table
as
	return
	(
		select MaDT, MaThuoc, SoLuong, CachDung
		from CT_DonThuoc
		where MaDT = @MaDT
	)

--Kiểm thử
select * from f_chithietdonthuoctheomadon('DT003')

--Hàm xem danh sách các hóa đơn đã lập với tham số truyền vào là mã NV
create function f_danhsachhoadontheomanv(@MaNV char(6))
returns table
as
	return
		(
			select NV.MaNV,HoNV +' '+TenNV as HoTen,MaHD,NgayLapHD,TrangThai
			from HoaDon as HD
			join NhanVien as NV
			on HD.MaNV = NV.MaNV
			where HD.MaNV = @MaNV
		)
--- Kiểm thử
select * from f_danhsachhoadontheomanv('NV0001')

--Hàm đếm số lượng hóa đơn lập được theo từng nhân viên, nhân viên k lập hóa đơn để null
create function f_hoadontheonhanvien()
returns table
as
	return
		(
			SELECT 
			 NV.MaNV, 
			 NV.HoNV + ' ' + NV.TenNV AS HoTen, 
				NULLIF(COUNT(HD.MaHD),0) AS SoLuongHoaDon
			FROM NhanVien AS NV
			LEFT JOIN HoaDon AS HD ON 
			NV.MaNV = HD.MaNV
			GROUP BY NV.MaNV, NV.HoNV, NV.TenNV 
		)

--Kiểm thử
select * from f_hoadontheonhanvien()

--Cách 2
create function f_hoadontheonhanvien_c2()
returns table
as
return
    (
        select 
            NV.MaNV,
            NV.HoNV + ' ' + NV.TenNV AS HoTen,
            nullif(COUNT(DanhSachChiTiet.MaHD),0) AS SoLuongHoaDon
        from NhanVien AS NV
        outer apply f_danhsachhoadontheomanv(NV.MaNV) AS DanhSachChiTiet 
        group by NV.MaNV, NV.HoNV, NV.TenNV
    )

--Kiểm thử
select * from f_hoadontheonhanvien_c2()

--Hàm xem số lượng tồn của Vaccine với tham số truyền vào là MaVaccine
create function f_soluongtonvaccine(@MaVaccine char(6))
returns int
as
begin
    declare @SoLuongTon int
    select  @SoLuongTon = SUM(SoLuong)
    from Lo_Vaccine
    where MaVaccine = @MaVaccine
    
    return @SoLuongTon
end

--Kiểm thử 
select dbo.f_soluongtonvaccine('VC001') as TongSoLuongTon

--Hàm phân nhóm tuổi của từng bệnh nhân theo chuẩn who   
create function f_PhanNhomTuoi(@NgaySinh DATETIME)
returns nvarchar(50)
as
begin
    declare @Tuoi INT = YEAR(GETDATE()) - YEAR(@NgaySinh) 
    return case
        when @Tuoi < 1 then N'Sơ sinh'               
        when @Tuoi BETWEEN 1 AND 9 then N'Trẻ em'              
        when @Tuoi BETWEEN 10 AND 19 then N'Vị thành niên'      
        when @Tuoi BETWEEN 20 AND 24 then N'Thanh niên'         
        when @Tuoi BETWEEN 25 AND 59 then N'Người trưởng thành'
        else N'Người cao tuổi'                               
    end
end

--Kiểm thử
SELECT 
    HoBN, 
    TenBN, 
    dbo.f_PhanNhomTuoi(NgaySinhBN) as NhomDoiTuong 
FROM BenhNhan;

--Hàm tính tổng tiền dịch vụ với tham số truyền vào là MaHS
create function f_tongtiendichvu(@MaHS char(6))
returns decimal(16,2)
as
begin
    declare @TongTienPhaiTra decimal(16,2);
    with TienDVLe as (
        select 
            CTDV.MaHS,
            case
                when DV.TrongDanhMucBHYT = 'BHYT' then (CTDV.SoLanSD * CTDV.DGiaDVTT) * 0.2
                else CTDV.SoLanSD * CTDV.DGiaDVTT
            end as TienTungDichVu
        from CT_DichVu as CTDV
        JOIN DichVu as DV ON CTDV.MaDV = DV.MaDV
        where CTDV.MaHS = @MaHS 
    )
    select @TongTienPhaiTra = SUM(TienTungDichVu) 
    from TienDVLe;
    return ISNULL(@TongTienPhaiTra, 0);
end

--Kiểm thử 
select dbo.f_tongtiendichvu('HS0001') as TongTienDichVu

--Hàm tính tổng tiền thuốc với tham số truyền vào là MaHS
create function f_tongtienthuoc(@MaHS char(6))
returns decimal(16,2)
as
begin
    declare @TienThuocBenhNhanTra decimal(16,2)

    select @TienThuocBenhNhanTra = SUM(
        case 
            when T.TrongDanhMucBHYT = 'BHYT' then (CTDT.SoLuong * CTDT.DGiaBanTT) * 0.2
            else (CTDT.SoLuong * CTDT.DGiaBanTT)
        end
    )
    from DonThuoc as DT
    JOIN CT_DonThuoc as CTDT ON DT.MaDT = CTDT.MaDT
    JOIN Thuoc as T ON CTDT.MaThuoc = T.MaThuoc
    where DT.MaHS = @MaHS

	return ISNULL(@TienThuocBenhNhanTra, 0)
end

--Kiểm thử
select dbo.f_tongtienthuoc('HS0001') as TongTienThuoc

--Hàm tính tiền hóa đơn với tham số truyền vào là MaHS
create function f_tongtienhoadon(@MaHS char(6))
returns decimal(16,2)
as	
	begin
		declare @TongTien decimal(16,2)
		select @TongTien = dbo.f_tongtienthuoc(@MaHS) + dbo.f_tongtiendichvu(@MaHS)
		return @TongTien	
	end

--Kiểm thử
select dbo.f_tongtienhoadon('HS0001') as ThanhTien


-----STORE PROCEDURE------
--Tạo thủ tục xem danh sách bệnh nhân với 2 tham số truyền vào là TuNam và DenNam
create procedure sp_xemdanhsachbenhnhan
		@TuNam int,
		@DenNam int
as
	begin
		select *
		from BenhNhan
		where YEAR(NgaySinhBN) between @TuNam and @DenNam
	end

--Kiểm thử
execute sp_xemdanhsachbenhnhan @TuNam = 1997, @DenNam = 2005
--Tạo thủ tục xem thông tin khám bệnh với tham số truyền vào là MaBN
create procedure sp_xemthongtinkham
    @MaBN char(6)
as
begin
    select 
        HS.MaHS,
        HS.NgayKham,
        HS.ChuanDoan,
        HS.KetLuan,
        NV.HoNV + ' ' + NV.TenNV as BacSiPhuTrach
    from HoSoKham as HS
    join NhanVien as NV on HS.MaNV = NV.MaNV
    where HS.MaBN = @MaBN
    order by HS.NgayKham DESC
end

--Kiểm thử
execute sp_xemthongtinkham 'BN0019'

--Tạo thủ tục xem đơn giá bán của một loại thuốc với tham số truyền vào ma MaThuoc
create procedure sp_xemdongiathuoc(@MaThuoc char(6))
as
	begin
		select MaThuoc,TenThuoc,DonGiaBan,DonViTinh
		from Thuoc
		where MaThuoc = @MaThuoc
	end

--Kiểm thử
execute sp_xemdongiathuoc 'T001'

----Tạo thủ tục xem thông tin của bệnh nhân với tham số truyền vào là MaBN
--create procedure sp_thongtinbenhnhan(@MaBN char(6))
--as
--	begin
--		select * 
--		from BenhNhan
--		where MaBN = @MaBN
--	end
-- Kiểm thử
--execute sp_thongtinbenhnhan 'BN0001'

--Tạo thủ tục xem danh sách 10 loại thuốc kê nhiều nhất theo tháng năm
create procedure sp_top10thuockenhieu(@Thang int, @Nam int)
as
	begin
		select top 10 with ties  CTDT.MaThuoc, TenThuoc,DonViTinh,
		count(CTDT.MaThuoc) as SoLuotKeDon,
		sum(CTDT.SoLuong) as TongSoLuong
		from CT_DonThuoc as CTDT 
				join 
			 Thuoc as T
				on CTDT.MaThuoc = T.MaThuoc
				join
			DonThuoc as DT
				on CTDT.MaDT = DT.MaDT
		where YEAR(DT.NgayKe) = @Nam and (@Thang = 0 or MONTH(DT.NgayKe) = @Thang)
		group by CTDT.MaThuoc, TenThuoc,DonViTinh
		order by SoLuotKeDon DESC
	end

--Kiểm thử
-- Xem top thuốc của tháng 5 năm 2025
EXEC sp_top10thuockenhieu @Thang = 5, @Nam = 2025;
-- Xem top thuốc của cả năm 2025
EXEC sp_top10thuockenhieu @Thang = 0, @Nam = 2025;

--Tạo thủ tục 5 dịch vụ dùng nhiều nhất
create procedure sp_top5dichvu(@Thang int , @Nam int)
as
	begin
		select top 5 with ties CTDV.MaDV,TenDV, count(CTDV.MaDV) as TongSoLuotSuDung, 
		sum(SoLanSD) as TongSoLanSuDung
		from CT_DichVu as CTDV
				join
			 DichVu as DV
				on CTDV.MaDV = DV.MaDV
			 join HoSoKham as HSK
				on CTDV.MaHS = HSK.MaHS
		where YEAR(HSK.NgayKham) = @Nam and (@Thang = 0 or MONTH(HSK.NgayKham) = @Thang)
		group by CTDV.MaDV,TenDV
		order by TongSoLuotSuDung DESC
	end

--Kiểm thử
-- Xem top dịch vụ của tháng 5 năm 2025
EXEC sp_top5dichvu @Thang = 5, @Nam = 2025

-- Xem top dịch vụ của cả năm 2025
EXEC sp_top5dichvu  @Thang=0, @Nam = 2025

--Thủ tục báo cáo doanh thu theo tháng với tham số truyền vào là Nam
create procedure sp_doanhthuthang(@Nam int)
as
	begin
		select MONTH(NgayLapHD) as Thang,
			   sum(dbo.f_tongtienhoadon(MaHS)) as DoanhThu
		from HoaDon
		where YEAR(NgayLapHD) = @Nam 
				and TrangThai = N'Đã thanh toán'
		group by MONTH(NgayLapHD)
	end

--Kiểm thử
execute sp_doanhthuthang @Nam = '2025'
select * from PhieuTiemChung
select B.MaBN,B.GioiTinh,datediff(Year,b.NgaySinhBN,t.NgayTiem) as Tuoi, T.ThanNhiet,T.NhipTim,T.HuyetAp,T.CanNang,CT.MuiThu,CT.PhanUngSauTiem,CT.MucDoPhanUng,CT.ThoiGianKhoiPhat
from
PhieuTiemChung as T join CT_PhieuTiemChung as CT on T.MaPhieuTC = CT.MaPhieuTC
	join Lo_Vaccine as LVC on CT.MaLoVaccine = LVC.MaLoVaccine
	join Vaccine as V on LVC.MaVaccine = V.MaVaccine
	
	join BenhNhan as B on B.MaBN = T.MaBN

	SELECT
    pt.MaPhieuTC,
    bn.HoBN + ' ' + bn.TenBN AS HoTen,
    DATEDIFF(YEAR, bn.NgaySinhBN, pt.NgayTiem) AS Tuoi, -- Tính tuổi để phân nhóm
    pt.CanNang,
    v.TenVaccine,
    ct.MucDoPhanUng -- Đây là biến mục tiêu (0, 1, 2)
FROM PhieuTiemChung pt
JOIN CT_PhieuTiemChung ct ON pt.MaPhieuTC = ct.MaPhieuTC
JOIN BenhNhan bn ON pt.MaBN = bn.MaBN
JOIN Lo_Vaccine l ON ct.MaLoVaccine = l.MaLoVaccine
JOIN Vaccine v ON l.MaVaccine = v.MaVaccine
WHERE pt.CanNang IS NOT NULL -- Chỉ lấy phiếu có cân nặng
ORDER BY pt.CanNang ASC;
--Tạo thủ tục xem thuốc hết hạn chưa với tham số truyền vào là MaThuoc
--Kết quả trả về là HSD với dạng ngày HSD dưới 90 ngày là sắp hết hạn, số âm là cần tiêu hủy..
create procedure sp_xemthuochethanchua(@MaThuoc char(6))
as
begin
    select 
        MaLo,
        MaThuoc,
        HSD,
        DATEDIFF(day, GETDATE(), HSD) as HanSuDungConLai,
        case
            when HSD < GETDATE() then N'Hết hạn' 
            when HSD <= DATEADD(day, 90, GETDATE()) then N'Sắp hết hạn'
            else N'Còn hạn'
        end as TrangThai
    from KhoThuoc
    where MaThuoc = @MaThuoc
    order by HSD ASC
end
	
--Kiểm thử thuốc còn hạn
execute sp_xemthuochethanchua 'T001'
--Kiểm thử sắp hết hạn
execute sp_xemthuochethanchua 'T003'
--Kiểm thử hết hạn
execute sp_xemthuochethanchua 'T002'
--Tạo thủ tục thêm phiếu nhập thuốc (có giao dịch)
create procedure sp_insertphieunhapthuoc
				(@MaPN char(6),
				 @NgayLapPN datetime,
				 @NgayNhap datetime,
				 @MaNV char(6))
as	
begin
	begin try
		begin transaction
		if exists (select 1 from PhieuNhap where MaPN = @MaPN)
			begin
				print N'Phiếu nhập đã tồn tại'
				rollback transaction
				return
			end

		insert into PhieuNhap (MaPN, NgayLapPN, NgayNhap, MaNV)
        values (@MaPN, @NgayLapPN, @NgayNhap, @MaNV)

		commit transaction
		print N'Thêm thành công'
	end try
	begin catch
		rollback transaction
		print error_message()
	end catch
end

--Kiểm thử
execute sp_insertphieunhapthuoc @MaPN = 'PN0021',
							@NgayNhap ='2025-12-2',
							@NgayLapPN = '2025-10-14',
							@MaNV = 'NV002'


create type dsthuocnhap as table
(
	MaThuoc char(6),
	SoLuong int,
	DonGia decimal(18,2),
	HSD datetime,
	MaLo char(6)
)

create procedure sp_nhapkhothuoc
    @MaPN char(6),
    @NgayLapPN datetime,
    @NgayNhap datetime,
    @MaNV char(6),
    @DanhSachThuoc dsthuocnhap readonly
as
begin
    begin try
        begin transaction
        if not exists (select 1 from PhieuNhap where MaPN = @MaPN)
        begin
            insert into PhieuNhap (MaPN, NgayLapPN, NgayNhap, MaNV)
            values (@MaPN, @NgayLapPN, @NgayNhap, @MaNV)
        end
		--thêm chi tiêt pn
        insert into CT_PhieuNhap (MaPN, MaThuoc, SoLuong, DGiaNhap,HSDThuoc)
        select @MaPN, MaThuoc, SoLuong, DonGia, HSD
        from @DanhSachThuoc

        -- Cập nhật Kho Thuốc
        
		 -- Cập nhật cộng dồn cho các lô đã có
        update KhoThuoc
        set SoLuongTon = KT.SoLuongTon + DS.SoLuong
        from KhoThuoc as KT
        join @DanhSachThuoc as DS 
        on KT.MaThuoc = DS.MaThuoc and KT.MaLo = DS.MaLo

        -- Thêm mới các lô nếu chưa có trong kho
        insert into KhoThuoc (MaLo, MaThuoc, SoLuongTon, DGiaNhap, HSD)
        select MaLo, MaThuoc, SoLuong, DonGia, HSD
        from @DanhSachThuoc as DS
        where not exists (
            select 1 from KhoThuoc K 
            where K.MaThuoc = DS.MaThuoc and K.MaLo = DS.MaLo
        )

        commit transaction
        print N'Thêm thành công'
    end try

    begin catch
        rollback transaction
        print error_message()
    end catch
end
select * from KhoThuoc
--Kiểm thử
--khai báo danh sách
declare @listdsthuoc dsthuocnhap

insert into @listdsthuoc (MaThuoc, SoLuong, DonGia, HSD, MaLo)
VALUES 
('T001', 100, 400, '2026-12-31', 'L001'), -- Thuốc	t001: Lô L001
('T004', 50, 1500, '2026-11-20', 'L004') -- Thuốc t004: Lô L004

select * from @listdsthuoc
execute sp_nhapkhothuoc
    @MaPN = 'PN0021',       
    @NgayLapPN = '2025-12-02',
    @NgayNhap = '2025-12-02',
    @MaNV = 'NV0003',
    @DanhSachThuoc = @listdsthuoc

-- Xem Phiếu nhập đã tạo chưa
SELECT * FROM PhieuNhap WHERE MaPN = 'PN0021';
-- Xem Chi tiết phiếu nhập đã có đủ 2 dòng chưa
SELECT * FROM CT_PhieuNhap WHERE MaPN = 'PN0021';
-- Xem Kho thuốc đã được cập nhật chưa
SELECT * FROM KhoThuoc WHERE MaLo IN ('L001', 'L004')	

--Tạo thủ tục cập nhật đơn giá trong bảng dịch vụ 
create procedure sp_updategiadichvu
    (@MaDV char(6), 
     @DonGiaDV decimal(18,2))
as	
begin

    begin try
		begin transaction
        if not exists (SELECT 1 FROM DichVu WHERE MaDV = @MaDV)
        begin
			print N'Mã dịch vụ không tồn tại'
            rollback transaction
			return 
        end
 
        UPDATE DichVu
        SET DonGiaDV = @DonGiaDV
        WHERE MaDV = @MaDV;

      
        commit transaction
        PRINT N'Cập nhật thành công'
    end try
    begin catch
        rollback transaction
		print error_message()
    end catch
end

--Kiểm thử

execute sp_updategiadichvu @MaDV = 'DV001', @DonGiaDV = 27000x

-- Kiểm tra lại
SELECT * FROM DichVu WHERE MaDV = 'DV001'
--Tạo thủ tục thêm một hồ sơ khám mới ( có giao dịch)
create procedure sp_themhosokham
    (@MaHS char(6),
     @NgayKham datetime,
     @ChuanDoan nvarchar(100),
     @KetLuan nvarchar(100),
     @MaNV char(6),
     @MaBN char(6))
as
begin
    begin try
        begin transaction

        IF EXISTS (SELECT 1 FROM HoSoKham WHERE MaHS = @MaHS)
        begin
            rollback tran
            return
        end
        -- 2. Thực hiện Insert
        insert into HoSoKham(MaHS, NgayKham, ChuanDoan, KetLuan, MaNV, MaBN)
        values(@MaHS, @NgayKham, @ChuanDoan, @KetLuan, @MaNV, @MaBN);

        commit tran
        print N'Thêm thành công';
	end try
    
	begin catch
        rollback transaction
		print N'Lỗi' + error_message()
    end catch
end

-- kiểm thử
EXEC sp_themhosokham 
    @MaHS = 'HS0022',
    @NgayKham = '2025-12-02 08:30:00',
    @ChuanDoan = N'Viêm họng cấp',
    @KetLuan = N'Kê đơn thuốc kháng sinh và nghỉ ngơi',
    @MaNV = 'NV0001', 
    @MaBN = 'BN0018' 

--Kiểm thử sai thông tin lúc insert into
EXEC sp_themhosokham 
    @MaHS = 'HS0022',
    @NgayKham = '2025-12-02 08:30:00',
    @ChuanDoan = N'Viêm họng cấp',
    @KetLuan = N'Kê đơn thuốc kháng sinh và nghỉ ngơi',
    @MaNV = 'NV001', 
    @MaBN = 'BN0018' 

--Tạo thủ tục kê đơn thuốc , trừ tồn kho ( có giao dịch)

-- Tạo kiểu dữ liệu để chứa danh sách thuốc bác sĩ kê
CREATE TYPE DanhSachKeDon AS TABLE
(
	MaThuoc char(6),
	MaLo char(6),      
	SoLuong int,
	GiaBan decimal(18,2),
	CachDung nvarchar(200)
)
create procedure sp_kedonthuoc
    -- THÔNG TIN ĐƠN THUỐC 
    @MaDT char(6),
    @NgayKe datetime, 
    @MaHS char(6),
    @DanhSachThuoc DanhSachKeDon READONLY
as
begin
    begin try
        begin tran

        -- 1. kiểm tra tồn kho
        -- Tìm xem có thuốc nào trong danh sách kê mà số lượng > tồn kho không
        declare @Thuocthieu nvarchar(100)
        
        SELECT TOP 1 @Thuocthieu = T.TenThuoc
        FROM @DanhSachThuoc AS DS
        JOIN KhoThuoc AS K ON DS.MaThuoc = K.MaThuoc AND DS.MaLo = K.MaLo
        JOIN Thuoc AS T ON DS.MaThuoc = T.MaThuoc
        WHERE DS.SoLuong > K.SoLuongTon

        IF @Thuocthieu IS NOT NULL -- tồn tại thuốc thiếu hàng
        begin
   
            print N'Thuốc ' + @ThuocLoi + N' không đủ số lượng tồn kho!'
            rollback tran
            return
        end

        -- 2. tạo đơn thuốc
        IF NOT EXISTS (SELECT 1 FROM DonThuoc WHERE MaDT = @MaDT)
        begin
            insert into DonThuoc (MaDT, NgayKe,MaHS) 
            values (@MaDT, @NgayKe, @MaHS)
        end

        -- 3. tạo chi tiết đơn thuốc
        INSERT INTO CT_DonThuoc (MaDT, MaThuoc, SoLuong, DGiaBanTT, CachDung)
        SELECT @MaDT, MaThuoc, SoLuong, GiaBan, CachDung
        FROM @DanhSachThuoc

        -- 4. trừ tồn kho
        UPDATE KhoThuoc
        SET SoLuongTon = KhoThuoc.SoLuongTon - DS.SoLuong
        FROM KhoThuoc
        JOIN @DanhSachThuoc AS DS 
        ON KhoThuoc.MaThuoc = DS.MaThuoc AND KhoThuoc.MaLo = DS.MaLo

        commit tran
        print N'Kê đơn thành công'
    end try
    begin catch
        rollback tran
        print N'Lỗi : ' + ERROR_MESSAGE()
    end catch
end

--Kiểm thử
DECLARE @DonThuocMau DanhSachKeDon
INSERT INTO @DonThuoc (MaThuoc, MaLo, SoLuong, GiaBan, CachDung)
VALUES 
('T001', 'L001', 10, 2000, N'Sáng 1 viên, Chiều 1 viên'), -- Thuốc 1
('T002', 'L002', 5, 5000, N'Uống sau ăn');                 -- Thuốc 2

-- 2. Gọi thủ tục
EXEC sp_kedon_toandien 
    @MaDT = 'DT9999',
    @NgayKe = '2025-12-02',
    @ChuanDoan = N'Cảm cúm',
    @MaNV = 'NV001',
    @MaHS = 'HS0010',
    @DanhSachThuoc = @DonThuocMau -- Truyền danh sách vào
	
-- 3. Kiểm tra kết quả
-- SELECT * FROM DonThuoc WHERE MaDT = 'DT9999'
-- SELECT * FROM CT_DonThuoc WHERE MaDT = 'DT9999'
-- SELECT * FROM KhoThuoc WHERE MaLo IN ('L001', 'L002')


-----TRIGGER--------

--Tạo trigger thêm một hóa đơn thì đặt mặc định là chưa thanh toán
create trigger tg_Default_HoaDon
on HoaDon
for insert
as
begin
    UPDATE HoaDon
    SET TrangThai = N'Chưa thanh toán'
    FROM HoaDon HD JOIN inserted I ON HD.MaHD = I.MaHD
    WHERE I.TrangThai IS NULL;
end

--Kieemr thu
--không đặt trạng thái
INSERT INTO HoaDon(MaHD, NgayLapHD,  MaNV, MaHS)
VALUES ('HD021', GETDATE(),  'NV0002', 'HS0021')

-- Kiểm tra lại kết quả
SELECT * FROM HoaDon WHERE MaHD = 'HD021';

--Số lượng tồn của thuốc phải lớn hơn hoặc bằng 0 
create trigger tg_soluongtonthuoc
on KhoThuoc
for update,insert
as
	if exists (select 1 from inserted where inserted.SoLuongTon < 0)
	begin
		print N'Số lượng tồn phải lớn hơn hoặc bằng 0'
		rollback transaction
	end
--Kiểm thử

UPDATE KhoThuoc
SET SoLuongTon = -5
WHERE MaThuoc = 'T001'
--Số lượng tồn của Vaccine phải lớn hơn hoặc bằng 0
create trigger tg_soluongtonvaccine
on Lo_Vaccine
for insert,update
as
	if exists (select 1 from inserted where inserted.SoLuong <0)
	begin
		print N'Số lượng tồn phải lớn hơn hoặc bằng 0'
		rollback transaction
	end
	
--kiem thu
UPDATE Lo_Vaccine
SET SoLuong = -10
WHERE MaLoVaccine = 'LVC001'

-- Ngày  nhận hàng phải lớn hơn hoặc bằng ngày đặt hàng của phiếu nhập
create trigger tg_datediff
on PhieuNhap
for insert, update
as
	if exists (select 1 from inserted where inserted.NgayLapPN > inserted.NgayNhap)
	begin
		print N'Ngày lập phiếu phải nhỏ hơn ngày nhận hàng'
		rollback transaction
	end

--Kiểm thử
	-- Giả sử hôm nay là 2025-12-3
-- Lập phiếu ngày 15, nhưng Ngày nhập lùi lại 5 ngày)
INSERT INTO PhieuNhap (MaPN, NgayLapPN, NgayNhap, MaNV)
VALUES ('PN0022', '2025-12-3', '2025-11-28', 'NV0003');

--Giới tính nhân viên có giá trị Nam hoặc Nữ 
create trigger tg_gioitinhnv
on NhanVien
for insert,update
as
	if exists (select 1 from inserted where  upper(inserted.Phai) not in ('NAM',N'NỮ'))
	begin
		print N'giới tính nhân viên phải là nam hoặc nữ'
		rollback transaction
	end

-- kIỂM THỬ
INSERT INTO NhanVien (MaNV, HoNV, TenNV, Phai)
VALUES ('NV0022', N'Nguyễn', N'Văn A', N'Khác')

--Ngày đặt hàng phải nhỏ hơn hoặc bằng ngày hiện hành
create trigger tg_datediffgetdate
on PhieuNhap_Vaccine
for insert,update
as
	if exists (select 1 from inserted where inserted.NgayLapPVC > GETDATE())
	begin
		print N'Ngày lập phiếu nhập vaccine phải nhỏ hơn ngày hiện hành'
		rollback transaction
	end

-- Giả sử hôm nay là ngày 3-12-2025. 
-- Ta dùng hàm DATEADD để cộng thêm 1 ngày vào thời điểm hiện tại (Ngày mai)
INSERT INTO PhieuNhap_Vaccine (MaPNVaccine, NgayLapPVC, NgayNhapVaccine, MaNV)
VALUES ('PNV021', DATEADD(day, 1, GETDATE()), GETDATE(), 'NV0002');
-----USER-----------
--Tạo user cho quản trị viên
-- Tạo Login và User cho Quản trị viên
create login qtv 
with password = '112233', 
default_database = QLyTramYTe

create user qtv for login qtv
alter role db_owner add member qtv

--Kiểm thử xóa hồ sơ khám
EXECUTE AS LOGIN = 'qtv';
delete from HoSoKham
where MaHS='HS0001'
REVERT;

-- Tạo Login và User cho Bác sĩ
create login bacsi 
WITH PASSWORD = '123231', 
DEFAULT_DATABASE = QLyTramYTe;
CREATE USER bacsi FOR LOGIN bacsi

-- Tra cứu thông tin để khám bệnh
GRANT SELECT ON BenhNhan TO bacsi
GRANT SELECT ON Thuoc TO bacsi       -- Xem thuốc để kê
GRANT SELECT ON DichVu TO bacsi      -- Xem dịch vụ để chỉ định
GRANT SELECT ON HoSoKham TO bacsi    -- Xem lịch sử khám cũ
GRANT SELECT ON DonThuoc TO bacsi
-- Cho phép Thêm/Sửa hồ sơ khám và đơn thuốc
GRANT INSERT, UPDATE ON HoSoKham TO bacsi;
GRANT INSERT, UPDATE ON DonThuoc TO bacsi;
GRANT INSERT, UPDATE ON CT_DonThuoc TO bacsi;
GRANT INSERT, UPDATE ON CT_DichVu TO bacsi;


--Kiểm thử update CT_DonThuoc
EXECUTE AS LOGIN = 'bacsi';
UPDATE CT_DonThuoc SET SoLuong = 5
where MaDT = 'DT003' and MaThuoc = 'T001'
REVERT;

--Tạo user cho dược sĩ
create login phuc
with password  = '123',
default_database =QLyTramYTe

CREATE USER phuc FOR LOGIN phuc;

GRANT SELECT, INSERT, UPDATE ON KhoThuoc TO phuc;
GRANT SELECT, INSERT, UPDATE ON Thuoc TO phuc;
GRANT SELECT ON DonThuoc TO phuc
GRANT SELECT ON CT_DonThuoc TO phuc

--kiểm thử select trên CT_DonThuoc
SELECT * FROM CT_DonThuoc
where MaDT ='DT003'

--Kiểm thử update trên CT_DonThuoc
EXECUTE AS LOGIN = 'phuc';
UPDATE CT_DonThuoc SET SoLuong = 5
where MaDT = 'DT003' and MaThuoc = 'T001'
REVERT;






